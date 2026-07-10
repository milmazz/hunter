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

  describe "generate_pkce/0" do
    test "returns an S256 verifier/challenge pair per RFC 7636" do
      %{
        code_verifier: verifier,
        code_challenge: challenge,
        code_challenge_method: "S256"
      } = Hunter.generate_pkce()

      assert String.length(verifier) == 43
      assert verifier =~ ~r/\A[A-Za-z0-9_-]+\z/
      assert challenge == Base.url_encode64(:crypto.hash(:sha256, verifier), padding: false)
    end

    test "verifiers are unique across calls" do
      assert Hunter.generate_pkce().code_verifier != Hunter.generate_pkce().code_verifier
    end
  end

  describe "authorization_url/3" do
    test "builds the authorize URL with defaults from the app" do
      url = Hunter.authorization_url(@app, "https://mastodon.example")

      %URI{scheme: "https", host: "mastodon.example", path: "/oauth/authorize", query: query} =
        URI.parse(url)

      assert URI.decode_query(query) == %{
               "response_type" => "code",
               "client_id" => "abc",
               "redirect_uri" => "urn:ietf:wg:oauth:2.0:oob",
               "scope" => "read write"
             }
    end

    test "forwards PKCE and extra params, preferring opts over app defaults" do
      url =
        Hunter.authorization_url(@app, "https://mastodon.example",
          redirect_uri: "https://app.example/cb",
          scope: "read",
          code_challenge: "xyz",
          code_challenge_method: "S256",
          state: "opaque",
          force_login: true
        )

      query = url |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()

      assert query == %{
               "response_type" => "code",
               "client_id" => "abc",
               "redirect_uri" => "https://app.example/cb",
               "scope" => "read",
               "code_challenge" => "xyz",
               "code_challenge_method" => "S256",
               "state" => "opaque",
               "force_login" => "true"
             }
    end

    test "prefers the first entry of redirect_uris when present" do
      app = %Hunter.Application{@app | redirect_uris: ["https://one.example/cb", "https://two.example/cb"]}

      query =
        app
        |> Hunter.authorization_url("https://mastodon.example")
        |> URI.parse()
        |> Map.fetch!(:query)
        |> URI.decode_query()

      assert query["redirect_uri"] == "https://one.example/cb"
    end
  end
end
