defmodule Hunter.OAuthTest do
  use Hunter.ReqCase, async: true

  @app %Hunter.Application{
    client_id: "abc",
    client_secret: "def",
    scopes: ["read", "write"],
    redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
  }

  describe "revoke_token/3" do
    test "revokes a token with client credentials" do
      stub_request(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/oauth/revoke"

        assert %{
                 "client_id" => "abc",
                 "client_secret" => "def",
                 "token" => "tok"
               } = read_json_body!(conn)

        respond_with(conn, %{})
      end)

      assert Hunter.revoke_token(@app, "tok", "https://mastodon.example") == true
    end

    test "a token that does not belong to the client raises Hunter.Error" do
      stub_request(fn conn ->
        respond_with(conn, %{error: "unauthorized_client"}, 403)
      end)

      assert_raise Hunter.Error, fn ->
        Hunter.revoke_token(@app, "someone-elses", "https://mastodon.example")
      end
    end
  end
end
