defmodule Hunter.StreamingServer do
  @moduledoc """
  In-process WebSocket server for streaming unit tests.

  `start/1` boots a Bandit listener on a random port whose plug reports the
  upgrade request to the test process and hands the socket to
  `Hunter.StreamingServer.Handler`. The test process receives:

    * `{:ws_request, path, query_params}` - the HTTP upgrade request
    * `{:ws_connected, handler_pid}` - the socket is up; message this pid
      to script the server (see the handler docs)
    * `{:ws_frame, decoded_json}` - each text frame the client sent
    * `{:ws_pong, data}` - the client answered a ping

  """

  @behaviour Plug

  import Plug.Conn

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, test_pid: test_pid) do
    conn = fetch_query_params(conn)
    send(test_pid, {:ws_request, conn.request_path, conn.query_params})

    WebSockAdapter.upgrade(conn, Hunter.StreamingServer.Handler, %{test_pid: test_pid}, [])
  end

  @doc """
  Starts the server under the test supervisor; returns `{pid, port}`.
  """
  def start(test_pid) do
    {:ok, server} =
      Bandit.start_link(
        plug: {__MODULE__, test_pid: test_pid},
        port: 0,
        ip: :loopback,
        startup_log: false
      )

    {:ok, {_ip, port}} = ThousandIsland.listener_info(server)
    {server, port}
  end
end
