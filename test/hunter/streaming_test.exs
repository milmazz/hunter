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
end
