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
  end

  defp client, do: Hunter.new(base_url: "https://mastodon.example", access_token: "123456")
end
