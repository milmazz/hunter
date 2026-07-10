defmodule Hunter.Streaming.Connection do
  # Owns the Mint conn + WebSocket state for one streaming connection.
  # Started via Hunter.Streaming.connect/2; not part of the public API.
  @moduledoc false

  use GenServer

  require Logger

  alias Hunter.Streaming.Event

  @handshake_timeout 15_000

  # OTP's gen_server accepts {:error, reason} from init/1 as a graceful
  # failure that doesn't crash linked callers; Elixir's GenServer callback
  # spec hasn't caught up with it yet.
  @dialyzer {:nowarn_function, init: 1}

  defstruct [:conn, :websocket, :ref, :subscriber]

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  @impl GenServer
  def init(opts) do
    uri = Keyword.fetch!(opts, :uri)
    subscriber = Keyword.fetch!(opts, :subscriber)
    streams = Keyword.get(opts, :streams, [])
    transport_opts = Keyword.get(opts, :transport_opts, [])

    {http_scheme, ws_scheme} = schemes(uri.scheme)
    path = uri.path <> "?" <> uri.query

    with {:ok, conn} <-
           Mint.HTTP.connect(http_scheme, uri.host, uri.port,
             protocols: [:http1],
             transport_opts: transport_opts
           ),
         {:ok, conn, ref} <- Mint.WebSocket.upgrade(ws_scheme, conn, path, []),
         {:ok, conn, status, headers} <- await_upgrade(conn, ref),
         # mode: :active is the default; passing it explicitly reaches new/5
         # directly because new/4's @spec trips a mint_web_socket typespec bug
         # (Mint.WebSocket.t declares fragment: tuple() while the struct
         # defaults it to nil), which makes dialyzer type new/4 as error-only.
         {:ok, conn, websocket} <- Mint.WebSocket.new(conn, ref, status, headers, mode: :active) do
      state = %__MODULE__{conn: conn, websocket: websocket, ref: ref, subscriber: subscriber}

      case subscribe_initial(state, streams) do
        {:ok, state} -> {:ok, state}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, reason} -> {:error, reason}
      {:error, _conn, reason} -> {:error, reason}
    end
  end

  @impl GenServer
  def handle_call({:control, type, stream, params}, _from, state) do
    frame =
      params
      |> Map.new(fn {key, value} -> {to_string(key), to_string(value)} end)
      |> Map.merge(%{"type" => type, "stream" => stream})

    case send_frame(state, {:text, Poison.encode!(frame)}) do
      {:ok, state} -> {:reply, :ok, state}
      {:error, state, reason} -> stop_with(state, {:error, reason}, {:reply, :ok})
    end
  end

  def handle_call(:close, _from, state) do
    case send_frame(state, {:close, 1_000, ""}) do
      {:ok, state} -> stop_with(state, :local, {:reply, :ok})
      {:error, state, _reason} -> stop_with(state, :local, {:reply, :ok})
    end
  end

  @impl GenServer
  def handle_info(message, state) do
    case Mint.WebSocket.stream(state.conn, message) do
      {:ok, conn, entries} ->
        handle_entries(entries, %{state | conn: conn})

      {:error, conn, reason, _responses} ->
        stop_with(%{state | conn: conn}, {:error, reason}, :noreply)

      :unknown ->
        {:noreply, state}
    end
  end

  defp handle_entries(entries, state) do
    frames =
      for {:data, ref, data} <- entries, ref == state.ref do
        data
      end

    Enum.reduce_while(frames, {:noreply, state}, fn data, {:noreply, state} ->
      case decode_frames(state, data) do
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
        Logger.warning("Hunter.Streaming: undecodable data: #{inspect(reason)}")
        {:noreply, %{state | websocket: websocket}}
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
      {:error, state, reason} -> stop_with(state, {:error, reason}, :noreply)
    end
  end

  defp dispatch_frames([{:close, code, _reason} | _rest], state) do
    stop_with(state, {:remote, code}, :noreply)
  end

  defp dispatch_frames([{:error, reason} | rest], state) do
    Logger.warning("Hunter.Streaming: skipping undecodable frame: #{inspect(reason)}")
    dispatch_frames(rest, state)
  end

  defp dispatch_frames([_other | rest], state), do: dispatch_frames(rest, state)

  defp subscribe_initial(state, streams) do
    Enum.reduce_while(streams, {:ok, state}, fn spec, {:ok, state} ->
      {stream, params} =
        case spec do
          {stream, params} -> {stream, params}
          stream when is_binary(stream) -> {stream, []}
        end

      frame =
        params
        |> Map.new(fn {key, value} -> {to_string(key), to_string(value)} end)
        |> Map.merge(%{"type" => "subscribe", "stream" => stream})

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

  defp stop_with(state, reason, reply_or_noreply) do
    send(state.subscriber, {:hunter_stream, self(), {:closed, reason}})
    Mint.HTTP.close(state.conn)

    case reply_or_noreply do
      {:reply, value} -> {:stop, :normal, value, state}
      :noreply -> {:stop, :normal, state}
    end
  end

  defp await_upgrade(conn, ref, status \\ nil, headers \\ nil) do
    receive do
      message ->
        case Mint.WebSocket.stream(conn, message) do
          {:ok, conn, entries} ->
            {status, headers} = collect_upgrade_entries(entries, ref, status, headers)

            cond do
              not Enum.any?(entries, &match?({:done, ^ref}, &1)) ->
                await_upgrade(conn, ref, status, headers)

              is_integer(status) and is_list(headers) ->
                {:ok, conn, status, headers}

              true ->
                {:error, :handshake_incomplete}
            end

          {:error, _conn, reason, _responses} ->
            {:error, reason}

          :unknown ->
            await_upgrade(conn, ref, status, headers)
        end
    after
      @handshake_timeout -> {:error, :handshake_timeout}
    end
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
