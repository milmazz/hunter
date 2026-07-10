defmodule Hunter.Streaming do
  @moduledoc """
  Real-time events over Mastodon's multiplexed streaming WebSocket.

  `connect/2` opens a connection process linked to the caller; parsed
  events arrive in the subscriber's mailbox as
  `{:hunter_stream, connection_pid, %Hunter.Streaming.Event{}}` and a
  single `{:hunter_stream, connection_pid, {:closed, reason}}` is sent
  when the socket closes. There is no automatic reconnection: supervise
  and restart the connection from the consuming application.

  Instances may serve streaming from a different host than the REST API;
  discover it via `Hunter.instance_info/1` under
  `configuration["urls"]["streaming"]` and pass it as the `:url` option.
  """

  alias Hunter.Config
  alias Hunter.Streaming.Connection

  @doc """
  Opens a streaming WebSocket connection linked to the caller.

  ## Parameters

    * `conn` - connection credentials
    * `opts` - option list

  ## Options

    * `streams` - initial subscriptions: stream names or `{name, params}`
      tuples, e.g. `["user", {"hashtag", tag: "elixir"}]`
    * `subscriber` - pid that receives events, default: the caller
    * `url` - streaming base URL override, e.g. `"wss://streaming.example"`
      (see the module docs for discovery)
    * `transport_opts` - Mint transport options, e.g.
      `[verify: :verify_none]` for self-signed certificates

  """
  @spec connect(Hunter.Client.t(), Keyword.t()) :: {:ok, pid} | {:error, term}
  def connect(%Hunter.Client{} = conn, opts \\ []) do
    case Connection.start_link(
           uri: ws_uri(conn, opts),
           subscriber: Keyword.get(opts, :subscriber, self()),
           streams: Keyword.get(opts, :streams, []),
           transport_opts: Keyword.get(opts, :transport_opts, [])
         ) do
      {:ok, pid} -> {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end

  defp ws_uri(%Hunter.Client{base_url: base_url, access_token: token}, opts) do
    base =
      case Keyword.fetch(opts, :url) do
        {:ok, url} ->
          String.trim_trailing(url, "/")

        :error ->
          base_url
          |> String.trim_trailing("/")
          |> String.replace_prefix("https://", "wss://")
          |> String.replace_prefix("http://", "ws://")
      end

    uri = URI.parse(base <> "/api/v1/streaming")
    %{uri | query: URI.encode_query(access_token: token), port: uri.port}
  end

  @doc """
  Checks the streaming server's health endpoint (Mastodon 2.5+).

  ## Parameters

    * `conn` - connection credentials
    * `opts` - `url:` overrides the streaming base URL (`ws://`/`wss://`
      accepted and mapped to `http://`/`https://`)

  Returns `true` only for a 200 response with an `OK` body; transport
  errors return `false`.
  """
  @spec health?(Hunter.Client.t(), Keyword.t()) :: boolean
  def health?(%Hunter.Client{} = conn, opts \\ []) do
    request =
      [
        method: :get,
        url: http_base_url(conn, opts) <> "/api/v1/streaming/health",
        decode_body: false,
        retry: false
      ] ++ Config.req_options()

    case Req.request(request) do
      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        String.trim(body) == "OK"

      _other ->
        false
    end
  end

  defp http_base_url(%Hunter.Client{base_url: base_url}, opts) do
    case Keyword.fetch(opts, :url) do
      {:ok, url} ->
        url
        |> String.replace_prefix("wss://", "https://")
        |> String.replace_prefix("ws://", "http://")
        |> String.trim_trailing("/")

      :error ->
        String.trim_trailing(base_url, "/")
    end
  end
end
