defmodule Hunter.Streaming.Connection do
  # Owns the Mint conn + WebSocket state for one streaming connection.
  # Started via Hunter.Streaming.connect/2; not part of the public API.
  @moduledoc false

  use GenServer

  require Logger

  alias Hunter.Streaming.Event

  @handshake_timeout 15_000
  @reconnect_defaults %{initial_backoff: 1_000, max_backoff: 30_000, max_attempts: :infinity}

  # OTP's gen_server accepts {:error, reason} from init/1 as a graceful
  # failure that doesn't crash linked callers; Elixir's GenServer callback
  # spec hasn't caught up with it yet.
  @dialyzer {:nowarn_function, init: 1}

  # conn/websocket/ref are nil between a drop and a successful reconnect;
  # subscriptions holds {stream, params_map} in subscription order so a
  # reconnect can replay them.
  defstruct [
    :conn,
    :websocket,
    :ref,
    :subscriber,
    :uri,
    :transport_opts,
    :reconnect,
    subscriptions: [],
    attempts: 0
  ]

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  @impl GenServer
  def init(opts) do
    uri = Keyword.fetch!(opts, :uri)
    subscriber = Keyword.fetch!(opts, :subscriber)
    streams = Keyword.get(opts, :streams, [])
    transport_opts = Keyword.get(opts, :transport_opts, [])
    reconnect = reconnect_config(Keyword.get(opts, :reconnect, false))

    state = %__MODULE__{
      subscriber: subscriber,
      uri: uri,
      transport_opts: transport_opts,
      reconnect: reconnect,
      subscriptions: Enum.map(streams, &normalize_stream_spec/1)
    }

    with {:ok, state} <- establish(state),
         {:ok, state} <- send_subscriptions(state) do
      {:ok, state}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @impl GenServer
  def handle_call({:control, "subscribe", stream, params}, _from, state) do
    subscription = normalize_stream_spec({stream, params})
    state = %{state | subscriptions: state.subscriptions -- [subscription]}
    state = %{state | subscriptions: state.subscriptions ++ [subscription]}

    send_control(state, "subscribe", subscription)
  end

  def handle_call({:control, "unsubscribe", stream, params}, _from, state) do
    subscription = normalize_stream_spec({stream, params})
    state = %{state | subscriptions: state.subscriptions -- [subscription]}

    send_control(state, "unsubscribe", subscription)
  end

  def handle_call(:close, _from, %{conn: nil} = state) do
    stop_with(state, :local, {:reply, :ok})
  end

  def handle_call(:close, _from, state) do
    state =
      case send_frame(state, {:close, 1_000, ""}) do
        {:ok, state} -> state
        {:error, state, _reason} -> state
      end

    stop_with(state, :local, {:reply, :ok})
  end

  @impl GenServer
  def handle_info(:reconnect, %{conn: nil} = state) do
    with {:ok, state} <- establish(state),
         {:ok, state} <- send_subscriptions(state) do
      send(state.subscriber, {:hunter_stream, self(), :reconnected})
      {:noreply, %{state | attempts: 0}}
    else
      {:error, reason} -> retry_or_stop(state, reason)
    end
  end

  # Stragglers from the torn-down socket while waiting to reconnect.
  def handle_info(_message, %{conn: nil} = state), do: {:noreply, state}

  def handle_info(message, state) do
    case Mint.WebSocket.stream(state.conn, message) do
      {:ok, conn, entries} ->
        handle_entries(entries, %{state | conn: conn})

      {:error, conn, reason, _responses} ->
        disconnect(%{state | conn: conn}, {:error, reason}, :noreply)

      :unknown ->
        {:noreply, state}
    end
  end

  defp send_control(%{conn: nil} = state, _type, _subscription) do
    # Disconnected: the updated subscription set is replayed on reconnect.
    {:reply, :ok, state}
  end

  defp send_control(state, type, {stream, params}) do
    frame = Map.merge(params, %{"type" => type, "stream" => stream})

    case send_frame(state, {:text, Poison.encode!(frame)}) do
      {:ok, state} -> {:reply, :ok, state}
      {:error, state, reason} -> disconnect(state, {:error, reason}, {:reply, :ok})
    end
  end

  defp handle_entries(entries, state) do
    frames =
      for {:data, ref, data} <- entries, ref == state.ref do
        data
      end

    Enum.reduce_while(frames, {:noreply, state}, fn data, {:noreply, state} ->
      case decode_frames(state, data) do
        # Disconnected mid-batch: the rest of the data is from the dead socket.
        {:noreply, %{conn: nil} = state} -> {:halt, {:noreply, state}}
        {:noreply, state} -> {:cont, {:noreply, state}}
        stop -> {:halt, stop}
      end
    end)
  end

  defp decode_frames(state, data) do
    case Mint.WebSocket.decode(state.websocket, data) do
      {:ok, websocket, frames} ->
        dispatch_frames(frames, %{state | websocket: websocket})

      {:error, websocket, reason} ->
        disconnect(%{state | websocket: websocket}, {:error, reason}, :noreply)
    end
  end

  defp dispatch_frames([], state), do: {:noreply, state}

  defp dispatch_frames([{:text, text} | rest], state) do
    case Event.parse(text) do
      {:ok, event} ->
        send(state.subscriber, {:hunter_stream, self(), event})

      {:error, reason} ->
        Logger.warning("Hunter.Streaming: skipping malformed frame: #{inspect(reason)}")
    end

    dispatch_frames(rest, state)
  end

  defp dispatch_frames([{:ping, data} | rest], state) do
    case send_frame(state, {:pong, data}) do
      {:ok, state} -> dispatch_frames(rest, state)
      {:error, state, reason} -> disconnect(state, {:error, reason}, :noreply)
    end
  end

  defp dispatch_frames([{:close, code, _reason} | _rest], state) do
    disconnect(state, {:remote, code}, :noreply)
  end

  # A frame-level decode error means the byte stream is desynced; anything
  # after it is garbage, so tear down rather than skip (unlike malformed
  # payload JSON, which arrives in a well-framed message and is skipped).
  defp dispatch_frames([{:error, reason} | _rest], state) do
    Logger.warning("Hunter.Streaming: undecodable frame, closing: #{inspect(reason)}")
    disconnect(state, {:error, reason}, :noreply)
  end

  defp dispatch_frames([_other | rest], state), do: dispatch_frames(rest, state)

  defp establish(state) do
    uri = state.uri
    {http_scheme, ws_scheme} = schemes(uri.scheme)
    path = uri.path <> "?" <> uri.query

    with {:ok, conn} <-
           Mint.HTTP.connect(http_scheme, uri.host, uri.port,
             protocols: [:http1],
             transport_opts: state.transport_opts
           ),
         {:ok, conn, ref} <- Mint.WebSocket.upgrade(ws_scheme, conn, path, []),
         {:ok, conn, status, headers} <- await_upgrade(conn, ref),
         # mode: :active is the default; passing it explicitly reaches new/5
         # directly because new/4's @spec trips a mint_web_socket typespec bug
         # (Mint.WebSocket.t declares fragment: tuple() while the struct
         # defaults it to nil), which makes dialyzer type new/4 as error-only.
         {:ok, conn, websocket} <- Mint.WebSocket.new(conn, ref, status, headers, mode: :active) do
      {:ok, %{state | conn: conn, websocket: websocket, ref: ref}}
    else
      {:error, reason} -> {:error, reason}
      {:error, _conn, reason} -> {:error, reason}
    end
  end

  defp send_subscriptions(state) do
    Enum.reduce_while(state.subscriptions, {:ok, state}, fn {stream, params}, {:ok, state} ->
      frame = Map.merge(params, %{"type" => "subscribe", "stream" => stream})

      case send_frame(state, {:text, Poison.encode!(frame)}) do
        {:ok, state} -> {:cont, {:ok, state}}
        {:error, _state, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp send_frame(state, frame) do
    case Mint.WebSocket.encode(state.websocket, frame) do
      {:ok, websocket, data} ->
        state = %{state | websocket: websocket}

        case Mint.WebSocket.stream_request_body(state.conn, state.ref, data) do
          {:ok, conn} -> {:ok, %{state | conn: conn}}
          {:error, conn, reason} -> {:error, %{state | conn: conn}, reason}
        end

      {:error, websocket, reason} ->
        {:error, %{state | websocket: websocket}, reason}
    end
  end

  # A non-local drop of an established connection: tear down for good, or
  # schedule a reconnect when the mode is enabled.
  defp disconnect(state, reason, reply_or_noreply) do
    case state.reconnect do
      nil ->
        stop_with(state, reason, reply_or_noreply)

      %{initial_backoff: backoff} ->
        send(state.subscriber, {:hunter_stream, self(), {:reconnecting, reason}})
        if state.conn, do: Mint.HTTP.close(state.conn)
        state = %{state | conn: nil, websocket: nil, ref: nil, attempts: 0}
        Process.send_after(self(), :reconnect, backoff)

        case reply_or_noreply do
          {:reply, value} -> {:reply, value, state}
          :noreply -> {:noreply, state}
        end
    end
  end

  defp retry_or_stop(state, reason) do
    attempts = state.attempts + 1

    if state.reconnect.max_attempts != :infinity and attempts >= state.reconnect.max_attempts do
      stop_with(state, {:error, reason}, :noreply)
    else
      Process.send_after(self(), :reconnect, backoff(state.reconnect, attempts))
      {:noreply, %{state | attempts: attempts}}
    end
  end

  defp backoff(%{initial_backoff: initial, max_backoff: max}, attempts) do
    min(initial * Integer.pow(2, attempts), max)
  end

  defp stop_with(state, reason, reply_or_noreply) do
    send(state.subscriber, {:hunter_stream, self(), {:closed, reason}})
    if state.conn, do: Mint.HTTP.close(state.conn)

    case reply_or_noreply do
      {:reply, value} -> {:stop, :normal, value, state}
      :noreply -> {:stop, :normal, state}
    end
  end

  defp reconnect_config(false), do: nil
  defp reconnect_config(true), do: @reconnect_defaults

  defp reconnect_config(opts) when is_list(opts) do
    Map.merge(@reconnect_defaults, Map.new(opts))
  end

  defp normalize_stream_spec({stream, params}) do
    {stream, Map.new(params, fn {key, value} -> {to_string(key), to_string(value)} end)}
  end

  defp normalize_stream_spec(stream) when is_binary(stream), do: {stream, %{}}

  # Messages that aren't part of the handshake (late traffic from a
  # previous socket, GenServer calls) are re-queued once it completes.
  defp await_upgrade(conn, ref, status \\ nil, headers \\ nil, pending \\ []) do
    receive do
      message ->
        case Mint.WebSocket.stream(conn, message) do
          {:ok, conn, entries} ->
            {status, headers} = collect_upgrade_entries(entries, ref, status, headers)

            cond do
              not Enum.any?(entries, &match?({:done, ^ref}, &1)) ->
                await_upgrade(conn, ref, status, headers, pending)

              is_integer(status) and is_list(headers) ->
                requeue(pending)
                {:ok, conn, status, headers}

              true ->
                requeue(pending)
                {:error, :handshake_incomplete}
            end

          {:error, _conn, reason, _responses} ->
            requeue(pending)
            {:error, reason}

          :unknown ->
            await_upgrade(conn, ref, status, headers, [message | pending])
        end
    after
      @handshake_timeout ->
        requeue(pending)
        {:error, :handshake_timeout}
    end
  end

  defp requeue(pending) do
    pending |> Enum.reverse() |> Enum.each(&send(self(), &1))
  end

  defp collect_upgrade_entries(entries, ref, status, headers) do
    Enum.reduce(entries, {status, headers}, fn
      {:status, ^ref, status}, {_status, headers} -> {status, headers}
      {:headers, ^ref, headers}, {status, _headers} -> {status, headers}
      _other, acc -> acc
    end)
  end

  defp schemes("wss"), do: {:https, :wss}
  defp schemes("ws"), do: {:http, :ws}
end
