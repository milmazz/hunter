defmodule Hunter.Api.RequestTest do
  use ExUnit.Case, async: true

  alias Hunter.Api.Request

  describe "process_request_body/1" do
    test "empty payload becomes an empty JSON object" do
      assert Request.process_request_body([]) == "{}"
    end

    test "binary payloads pass through untouched" do
      assert Request.process_request_body(~s({"status":"hi"})) == ~s({"status":"hi"})
    end

    test "maps are JSON-encoded" do
      assert Request.process_request_body(%{status: "hi"}) == ~s({"status":"hi"})
    end
  end

  describe "process_request_header/1" do
    test "sets the accept default as string tuples" do
      assert [{"accept", "application/json; charset=utf-8"}] = Request.process_request_header([])
    end

    test "caller headers are preserved and win over defaults" do
      headers =
        Request.process_request_header([
          {"authorization", "Bearer 123"},
          {"accept", "text/plain"}
        ])

      assert {"authorization", "Bearer 123"} in headers
      assert {"accept", "text/plain"} in headers
      refute {"accept", "application/json; charset=utf-8"} in headers
    end
  end

  describe "handle_response/1" do
    test "2xx responses return the body" do
      assert Request.handle_response({:ok, %Req.Response{status: 200, body: "ok"}}) ==
               {:ok, "ok"}

      assert Request.handle_response({:ok, %Req.Response{status: 204, body: ""}}) == {:ok, ""}
    end

    test "non-2xx responses return the body as error" do
      body = ~s({"error":"Record not found"})

      assert Request.handle_response({:ok, %Req.Response{status: 404, body: body}}) ==
               {:error, body}
    end

    test "transport errors return the reason" do
      assert Request.handle_response({:error, %Req.TransportError{reason: :econnrefused}}) ==
               {:error, :econnrefused}
    end
  end

  describe "split_payload/2" do
    test "GET routes data to query params with no body options" do
      assert Request.split_payload(:get, limit: 1, local: true) ==
               {[], [{"limit", "1"}, {"local", "true"}]}
    end

    test "DELETE routes data to query params" do
      assert Request.split_payload(:delete, %{domain: "spam.example"}) ==
               {[], [{"domain", "spam.example"}]}
    end

    test "list values encode as Rails-style repeated keys" do
      assert Request.split_payload(:get, %{id: [1, 2]}) ==
               {[], [{"id[]", "1"}, {"id[]", "2"}]}
    end

    test "empty data produces no params" do
      assert Request.split_payload(:get, []) == {[], []}
      assert Request.split_payload(:get, %{}) == {[], []}
    end

    test "write verbs keep the JSON body and produce no params" do
      assert Request.split_payload(:post, %{status: "hi"}) ==
               {[body: ~s({"status":"hi"})], []}

      assert Request.split_payload(:patch, []) == {[body: "{}"], []}
    end

    test "multipart payloads become form_multipart options on write verbs" do
      parts = [file: {"binary", filename: "image.png"}]

      assert Request.split_payload(:post, {:form_multipart, parts}) ==
               {[form_multipart: parts], []}
    end
  end

  describe "request/5 through the Req plug adapter" do
    test "GET sends query params, headers, and returns the raw body" do
      Req.Test.stub(__MODULE__, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/api/v1/timelines/home"
        assert conn.query_string == "limit=1&local=true"
        assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer 123"]

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, ~s([{"id":"1"}]))
      end)

      assert {:ok, ~s([{"id":"1"}])} =
               Request.request(
                 :get,
                 "https://mastodon.test/api/v1/timelines/home",
                 [limit: 1, local: true],
                 [{"authorization", "Bearer 123"}],
                 plug: {Req.Test, __MODULE__}
               )
    end

    test "POST sends a JSON body with the JSON content type" do
      Req.Test.stub(__MODULE__, fn conn ->
        assert conn.method == "POST"
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/json"]

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert Poison.decode!(body) == %{"status" => "hi"}

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, ~s({"id":"1"}))
      end)

      assert {:ok, ~s({"id":"1"})} =
               Request.request(
                 :post,
                 "https://mastodon.test/api/v1/statuses",
                 %{status: "hi"},
                 [],
                 plug: {Req.Test, __MODULE__}
               )
    end

    test "non-2xx responses surface the body as an error" do
      Req.Test.stub(__MODULE__, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(404, ~s({"error":"Record not found"}))
      end)

      assert {:error, ~s({"error":"Record not found"})} =
               Request.request(
                 :get,
                 "https://mastodon.test/api/v1/statuses/0",
                 [],
                 [],
                 plug: {Req.Test, __MODULE__}
               )
    end

    test "request!/5 raises Hunter.Error on failure" do
      Req.Test.stub(__MODULE__, fn conn ->
        Plug.Conn.send_resp(conn, 500, "boom")
      end)

      assert_raise Hunter.Error, fn ->
        Request.request!(
          :get,
          "https://mastodon.test/api/v1/instance",
          [],
          [],
          plug: {Req.Test, __MODULE__}
        )
      end
    end
  end
end
