defmodule Hunter.StreamingTest do
  use Hunter.ReqCase, async: true

  @conn Hunter.new(base_url: "https://mastodon.example", access_token: "123456")

  describe "health?/2" do
    test "is true when the streaming server answers OK" do
      stub_request(fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/api/v1/streaming/health"
        respond_with(conn, "OK")
      end)

      assert Hunter.Streaming.health?(@conn)
    end

    test "is false on any other response" do
      stub_request(fn conn -> respond_with(conn, "no", 404) end)

      refute Hunter.Streaming.health?(@conn)
    end

    test "is reachable as Hunter.streaming_health?/2 on the facade" do
      stub_request(fn conn ->
        assert conn.request_path == "/api/v1/streaming/health"
        respond_with(conn, "OK")
      end)

      assert Hunter.streaming_health?(@conn)
    end

    test "resolves a ws(s) url override to http(s)" do
      stub_request(fn conn ->
        assert conn.host == "streaming.example"
        respond_with(conn, "OK")
      end)

      assert Hunter.Streaming.health?(@conn, url: "wss://streaming.example")
    end
  end

  describe "connect/2" do
    test "handshakes with the access token and subscribes initial streams" do
      {_server, port} = Hunter.StreamingServer.start(self())

      assert {:ok, pid} =
               Hunter.Streaming.connect(client(),
                 url: "ws://localhost:#{port}",
                 streams: ["user", {"hashtag", tag: "elixir"}]
               )

      assert_receive {:ws_request, "/api/v1/streaming", %{"access_token" => "123456"}}
      assert_receive {:ws_connected, _ws}
      assert_receive {:ws_frame, %{"type" => "subscribe", "stream" => "user"}}

      assert_receive {:ws_frame,
                      %{"type" => "subscribe", "stream" => "hashtag", "tag" => "elixir"}}

      assert Process.alive?(pid)
    end

    test "delivers parsed events to the subscriber" do
      {_server, port} = Hunter.StreamingServer.start(self())
      {:ok, pid} = Hunter.Streaming.connect(client(), url: "ws://localhost:#{port}")
      assert_receive {:ws_connected, ws}

      status_json = File.read!(Path.expand(Path.join([__DIR__, "..", "fixtures", "status.json"])))

      frame =
        Poison.encode!(%{"stream" => ["user"], "event" => "update", "payload" => status_json})

      send(ws, {:push_text, frame})

      assert_receive {:hunter_stream, ^pid,
                      %Hunter.Streaming.Event{
                        type: "update",
                        payload: %Hunter.Status{id: "103270115826048975"}
                      }}
    end

    @tag :capture_log
    test "skips malformed frames and stays connected" do
      {_server, port} = Hunter.StreamingServer.start(self())
      {:ok, pid} = Hunter.Streaming.connect(client(), url: "ws://localhost:#{port}")
      assert_receive {:ws_connected, ws}

      send(ws, {:push_text, "not json"})

      send(
        ws,
        {:push_text,
         Poison.encode!(%{
           "stream" => ["user"],
           "event" => "update",
           "payload" =>
             File.read!(Path.expand(Path.join([__DIR__, "..", "fixtures", "status.json"])))
         })}
      )

      assert_receive {:hunter_stream, ^pid, %Hunter.Streaming.Event{type: "update"}}
      assert Process.alive?(pid)
    end

    test "returns an error when the endpoint refuses the upgrade" do
      # Nothing is listening on this port.
      assert {:error, _reason} = Hunter.Streaming.connect(client(), url: "ws://localhost:9")
    end

    test "accepts an http(s) url override, normalizing it to ws(s)" do
      {_server, port} = Hunter.StreamingServer.start(self())

      assert {:ok, _pid} =
               Hunter.Streaming.connect(client(), url: "http://localhost:#{port}")

      assert_receive {:ws_connected, _ws}
    end
  end

  describe "runtime control and close paths" do
    setup do
      {_server, port} = Hunter.StreamingServer.start(self())
      {:ok, pid} = Hunter.Streaming.connect(client(), url: "ws://localhost:#{port}")
      assert_receive {:ws_connected, ws}
      %{pid: pid, ws: ws}
    end

    test "subscribe/3 and unsubscribe/3 send control frames", %{pid: pid} do
      assert :ok = Hunter.Streaming.subscribe(pid, "list", list: "12")
      assert_receive {:ws_frame, %{"type" => "subscribe", "stream" => "list", "list" => "12"}}

      assert :ok = Hunter.Streaming.unsubscribe(pid, "list", list: "12")
      assert_receive {:ws_frame, %{"type" => "unsubscribe", "stream" => "list", "list" => "12"}}
    end

    test "answers server pings with pong, never surfacing them", %{pid: pid, ws: ws} do
      send(ws, :ping_client)

      assert_receive {:ws_pong, "hb"}
      refute_receive {:hunter_stream, ^pid, _}, 100
      assert Process.alive?(pid)
    end

    test "server close delivers {:closed, {:remote, code}} and exits normally", %{
      pid: pid,
      ws: ws
    } do
      ref = Process.monitor(pid)
      send(ws, {:close, 4_000})

      assert_receive {:hunter_stream, ^pid, {:closed, {:remote, 4_000}}}
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end

    @tag :capture_log
    test "framing-level garbage tears the connection down" do
      {_server, port} = Hunter.RawStreamingServer.start(self())
      {:ok, pid} = Hunter.Streaming.connect(client(), url: "ws://localhost:#{port}")
      assert_receive {:raw_ws_connected, raw}
      ref = Process.monitor(pid)

      # fin=1, reserved opcode 0x3, unmasked, empty payload: a frame no
      # conformant server emits, so the socket is presumed desynced.
      send(raw, {:push_raw, <<0x83, 0x00>>})

      assert_receive {:hunter_stream, ^pid, {:closed, {:error, _reason}}}
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end

    test "server going away delivers {:closed, {:error, reason}}", %{pid: pid, ws: ws} do
      ref = Process.monitor(pid)
      Process.exit(ws, :kill)

      assert_receive {:hunter_stream, ^pid, {:closed, _reason}}
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end

    test "close/1 sends a close frame and delivers {:closed, :local}", %{pid: pid} do
      ref = Process.monitor(pid)

      assert :ok = Hunter.Streaming.close(pid)
      assert_receive {:hunter_stream, ^pid, {:closed, :local}}
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end
  end

  describe "auto-reconnect" do
    test "reconnects after a remote close, resubscribing and notifying the subscriber" do
      {_server, port} = Hunter.StreamingServer.start(self())

      {:ok, pid} =
        Hunter.Streaming.connect(client(),
          url: "ws://localhost:#{port}",
          streams: ["user"],
          reconnect: [initial_backoff: 10]
        )

      assert_receive {:ws_connected, ws}
      assert_receive {:ws_frame, %{"type" => "subscribe", "stream" => "user"}}

      send(ws, {:close, 1_012})

      assert_receive {:hunter_stream, ^pid, {:reconnecting, {:remote, 1_012}}}
      assert_receive {:ws_connected, _ws2}
      assert_receive {:ws_frame, %{"type" => "subscribe", "stream" => "user"}}
      assert_receive {:hunter_stream, ^pid, :reconnected}
      assert Process.alive?(pid)
    end

    test "replays the runtime subscription set, not the initial one" do
      {_server, port} = Hunter.StreamingServer.start(self())

      {:ok, pid} =
        Hunter.Streaming.connect(client(),
          url: "ws://localhost:#{port}",
          streams: ["user"],
          reconnect: [initial_backoff: 10]
        )

      assert_receive {:ws_connected, ws}
      assert_receive {:ws_frame, %{"type" => "subscribe", "stream" => "user"}}

      :ok = Hunter.Streaming.subscribe(pid, "list", list: "12")
      assert_receive {:ws_frame, %{"type" => "subscribe", "stream" => "list"}}
      :ok = Hunter.Streaming.unsubscribe(pid, "user")
      assert_receive {:ws_frame, %{"type" => "unsubscribe", "stream" => "user"}}

      send(ws, {:close, 1_012})

      assert_receive {:ws_connected, _ws2}
      assert_receive {:ws_frame, %{"type" => "subscribe", "stream" => "list", "list" => "12"}}
      assert_receive {:hunter_stream, ^pid, :reconnected}
      refute_receive {:ws_frame, %{"type" => "subscribe", "stream" => "user"}}, 100
    end

    test "close/1 stays terminal when reconnect is enabled" do
      {_server, port} = Hunter.StreamingServer.start(self())

      {:ok, pid} =
        Hunter.Streaming.connect(client(),
          url: "ws://localhost:#{port}",
          reconnect: [initial_backoff: 10]
        )

      assert_receive {:ws_connected, _ws}
      ref = Process.monitor(pid)

      assert :ok = Hunter.Streaming.close(pid)
      assert_receive {:hunter_stream, ^pid, {:closed, :local}}
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end

    test "gives up with {:closed, reason} once max_attempts is exhausted" do
      {_server, port} = Hunter.StreamingServer.start(self())

      {:ok, pid} =
        Hunter.Streaming.connect(client(),
          url: "ws://localhost:#{port}",
          reconnect: [initial_backoff: 10, max_attempts: 2]
        )

      assert_receive {:ws_connected, ws}
      ref = Process.monitor(pid)

      :ok = stop_supervised(Hunter.StreamingServer)
      send(ws, {:close, 1_012})

      assert_receive {:hunter_stream, ^pid, {:reconnecting, _reason}}
      assert_receive {:hunter_stream, ^pid, {:closed, {:error, _reason}}}
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end
  end

  defp client, do: Hunter.new(base_url: "https://mastodon.example", access_token: "123456")
end
