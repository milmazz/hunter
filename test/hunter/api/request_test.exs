defmodule Hunter.Api.RequestTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Api.Request

  @conn Hunter.Client.new(base_url: "https://mastodon.example", access_token: "123456")

  describe "request!/6 with a %Hunter.Client{}" do
    test "GET joins the path onto base_url, encodes params, sets auth and accept headers" do
      stub_request(fn conn ->
        assert conn.method == "GET"
        assert conn.host == "mastodon.example"
        assert conn.request_path == "/api/v1/timelines/home"
        assert conn.query_string == "limit=1&local=true"
        assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer 123456"]
        assert Plug.Conn.get_req_header(conn, "accept") == ["application/json; charset=utf-8"]
        respond_with(conn, [%{id: "1"}])
      end)

      assert [%Hunter.Status{id: "1"}] =
               Request.request!(@conn, :get, "/api/v1/timelines/home", :statuses,
                 limit: 1,
                 local: true
               )
    end

    test "GET encodes list values as Rails-style repeated keys" do
      stub_request(fn conn ->
        assert conn.query_string == "id%5B%5D=1&id%5B%5D=2"
        respond_with(conn, [])
      end)

      assert [] = Request.request!(@conn, :get, "/api/v1/statuses", :statuses, %{id: [1, 2]})
    end

    test "POST sends a JSON body with the JSON content type" do
      stub_request(fn conn ->
        assert conn.method == "POST"
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/json"]
        assert read_json_body!(conn) == %{"status" => "hi"}
        respond_with_fixture(conn, "status")
      end)

      assert %Hunter.Status{} =
               Request.request!(@conn, :post, "/api/v1/statuses", :status, %{status: "hi"})
    end

    test "empty payload on a write verb sends an empty JSON object" do
      stub_request(fn conn ->
        assert read_json_body!(conn) == %{}
        respond_with_fixture(conn, "status")
      end)

      assert %Hunter.Status{} =
               Request.request!(@conn, :post, "/api/v1/statuses/1/reblog", :status)
    end

    test "extra headers from opts are sent alongside the auth header" do
      stub_request(fn conn ->
        assert Plug.Conn.get_req_header(conn, "idempotency-key") == ["abc123"]
        assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer 123456"]
        respond_with_fixture(conn, "status")
      end)

      assert %Hunter.Status{} =
               Request.request!(@conn, :post, "/api/v1/statuses", :status, %{status: "hi"},
                 headers: [{"idempotency-key", "abc123"}]
               )
    end

    test "to: nil returns the JSON-decoded body without struct transformation" do
      stub_request(fn conn -> respond_with(conn, %{count: 7}) end)

      assert %{"count" => 7} =
               Request.request!(@conn, :get, "/api/v1/notifications/unread_count", nil)
    end

    test "non-2xx responses raise Hunter.Error" do
      stub_request(fn conn -> respond_with(conn, %{error: "Record not found"}, 404) end)

      assert_raise Hunter.Error, fn ->
        Request.request!(@conn, :get, "/api/v1/statuses/0", :status)
      end
    end
  end

  describe "request!/6 with a bare base URL" do
    test "sends no authorization header" do
      stub_request(fn conn ->
        assert conn.request_path == "/api/v1/apps"
        assert Plug.Conn.get_req_header(conn, "authorization") == []

        respond_with(conn, %{
          client_id: "1234567890",
          client_secret: "1234567890",
          id: "1234"
        })
      end)

      assert %Hunter.Application{client_id: "1234567890", client_secret: "1234567890", id: "1234"} =
               Request.request!(
                 "https://mastodon.example",
                 :post,
                 "/api/v1/apps",
                 :application,
                 %{
                   client_name: "hunter"
                 }
               )
    end
  end
end
