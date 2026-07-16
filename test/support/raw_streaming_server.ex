defmodule Hunter.RawStreamingServer do
  @moduledoc """
  Bare `:gen_tcp` WebSocket server for framing-level failure tests.

  Performs the HTTP upgrade handshake and then writes whatever bytes the
  test scripts — desynced framing that a conformant WebSock server (such
  as `Hunter.StreamingServer`) cannot be made to produce.

  `start/1` returns `{pid, port}`; once a client upgrades, the test
  process receives `{:raw_ws_connected, pid}` and can message the pid:

    * `{:push_raw, binary}` - write raw bytes on the socket

  """

  @ws_magic "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

  @doc """
  Boots the listener on a random loopback port and accepts one client;
  returns `{pid, port}`.
  """
  def start(test_pid) do
    {:ok, listen} = :gen_tcp.listen(0, [:binary, ip: :loopback, active: false, reuseaddr: true])
    {:ok, port} = :inet.port(listen)
    pid = spawn_link(fn -> accept(listen, test_pid) end)
    {pid, port}
  end

  defp accept(listen, test_pid) do
    {:ok, socket} = :gen_tcp.accept(listen)
    {:ok, request} = recv_request(socket, "")
    :ok = :gen_tcp.send(socket, handshake_response(request))
    send(test_pid, {:raw_ws_connected, self()})
    loop(socket)
  end

  defp recv_request(socket, acc) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    acc = acc <> data

    if String.contains?(acc, "\r\n\r\n"), do: {:ok, acc}, else: recv_request(socket, acc)
  end

  defp handshake_response(request) do
    [_line, key] = Regex.run(~r/sec-websocket-key:\s*(\S+)/i, request)
    accept = Base.encode64(:crypto.hash(:sha, key <> @ws_magic))

    "HTTP/1.1 101 Switching Protocols\r\n" <>
      "upgrade: websocket\r\n" <>
      "connection: upgrade\r\n" <>
      "sec-websocket-accept: #{accept}\r\n\r\n"
  end

  defp loop(socket) do
    receive do
      {:push_raw, data} ->
        :ok = :gen_tcp.send(socket, data)
        loop(socket)
    end
  end
end
