defmodule Hunter.ClientTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Client

  @app %Hunter.Application{
    client_id: "abc",
    client_secret: "def",
    scopes: ["read", "write"],
    redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
  }

  describe "new/1" do
    test "builds a client with the given options" do
      conn = Client.new(base_url: "https://example.com", access_token: "123456")

      assert %Client{base_url: "https://example.com", access_token: "123456"} = conn
    end
  end

  test "user_agent/0 advertises hunter and its version" do
    assert Client.user_agent() == "Hunter.Elixir/#{Hunter.version()}"
  end

  describe "log_in/4" do
    test "exchanges a password grant for an access token" do
      stub_request(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/oauth/token"

        assert %{
                 "grant_type" => "password",
                 "username" => "user@example.com",
                 "password" => "secret",
                 "client_id" => "abc",
                 "client_secret" => "def",
                 "scope" => "read write"
               } = read_json_body!(conn)

        respond_with(conn, %{access_token: "tok"})
      end)

      assert %Client{base_url: "https://mastodon.example", access_token: "tok"} =
               Client.log_in(@app, "user@example.com", "secret", "https://mastodon.example")
    end

    test "invalid credentials raise Hunter.Error" do
      stub_request(fn conn ->
        respond_with(conn, %{error: "invalid_grant"}, 401)
      end)

      assert_raise Hunter.Error, fn ->
        Client.log_in(@app, "user@example.com", "wrong", "https://mastodon.example")
      end
    end
  end

  describe "log_in_oauth/3" do
    test "exchanges an authorization code for an access token" do
      stub_request(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/oauth/token"

        assert %{
                 "grant_type" => "authorization_code",
                 "code" => "auth-code",
                 "client_id" => "abc",
                 "client_secret" => "def",
                 "redirect_uri" => "urn:ietf:wg:oauth:2.0:oob"
               } = read_json_body!(conn)

        respond_with(conn, %{access_token: "tok"})
      end)

      assert %Client{base_url: "https://mastodon.example", access_token: "tok"} =
               Client.log_in_oauth(@app, "auth-code", "https://mastodon.example")
    end
  end
end
