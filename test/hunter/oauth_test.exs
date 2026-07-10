defmodule Hunter.OAuthTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Client

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
      app = %Hunter.Application{
        @app
        | redirect_uris: ["https://one.example/cb", "https://two.example/cb"]
      }

      query =
        app
        |> Hunter.authorization_url("https://mastodon.example")
        |> URI.parse()
        |> Map.fetch!(:query)
        |> URI.decode_query()

      assert query["redirect_uri"] == "https://one.example/cb"
    end

    test "raises on an unknown/misspelled option" do
      assert_raise ArgumentError, fn ->
        Hunter.authorization_url(@app, "https://mastodon.example", code_challange: "typo")
      end
    end
  end

  describe "log_in_oauth/4" do
    test "exchanges an authorization code for an access token" do
      stub_request(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/oauth/token"

        body = read_json_body!(conn)

        assert %{
                 "grant_type" => "authorization_code",
                 "code" => "auth-code",
                 "client_id" => "abc",
                 "client_secret" => "def",
                 "redirect_uri" => "urn:ietf:wg:oauth:2.0:oob"
               } = body

        refute Map.has_key?(body, "code_verifier")

        respond_with(conn, %{access_token: "tok"})
      end)

      assert %Client{base_url: "https://mastodon.example", access_token: "tok"} =
               Hunter.log_in_oauth(@app, "auth-code", "https://mastodon.example")
    end

    test "forwards the PKCE code_verifier when given" do
      stub_request(fn conn ->
        assert %{
                 "grant_type" => "authorization_code",
                 "code" => "auth-code",
                 "code_verifier" => "the-verifier"
               } = read_json_body!(conn)

        respond_with(conn, %{access_token: "tok"})
      end)

      assert %Client{access_token: "tok"} =
               Hunter.log_in_oauth(@app, "auth-code", "https://mastodon.example",
                 code_verifier: "the-verifier"
               )
    end

    test "uses the first redirect_uris entry when present" do
      stub_request(fn conn ->
        assert %{"redirect_uri" => "https://one.example/cb"} = read_json_body!(conn)
        respond_with(conn, %{access_token: "tok"})
      end)

      app = %Hunter.Application{@app | redirect_uris: ["https://one.example/cb"]}
      assert %Client{} = Hunter.log_in_oauth(app, "auth-code", "https://mastodon.example")
    end

    test "the redirect_uri option wins over the app's registered URI" do
      stub_request(fn conn ->
        assert %{"redirect_uri" => "https://two.example/cb"} = read_json_body!(conn)
        respond_with(conn, %{access_token: "tok"})
      end)

      assert %Client{} =
               Hunter.log_in_oauth(@app, "auth-code", "https://mastodon.example",
                 redirect_uri: "https://two.example/cb"
               )
    end

    test "raises on an unknown/misspelled option" do
      assert_raise ArgumentError, fn ->
        Hunter.log_in_oauth(@app, "auth-code", "https://mastodon.example", bogus: "typo")
      end
    end
  end

  describe "log_in_app/2" do
    test "exchanges client credentials for an app-level token" do
      stub_request(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/oauth/token"

        assert %{
                 "grant_type" => "client_credentials",
                 "client_id" => "abc",
                 "client_secret" => "def",
                 "scope" => "read write"
               } = read_json_body!(conn)

        respond_with(conn, %{access_token: "app-tok"})
      end)

      assert %Client{base_url: "https://mastodon.example", access_token: "app-tok"} =
               Hunter.log_in_app(@app, "https://mastodon.example")
    end

    test "omits scope when the app has none" do
      stub_request(fn conn ->
        body = read_json_body!(conn)
        refute Map.has_key?(body, "scope")
        respond_with(conn, %{access_token: "app-tok"})
      end)

      app = %Hunter.Application{@app | scopes: nil}
      assert %Client{access_token: "app-tok"} = Hunter.log_in_app(app, "https://mastodon.example")
    end
  end

  describe "oauth_server_metadata/1" do
    test "fetches RFC 8414 metadata unauthenticated" do
      stub_request(fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/.well-known/oauth-authorization-server"
        assert Plug.Conn.get_req_header(conn, "authorization") == []

        respond_with(conn, %{
          issuer: "https://mastodon.example/",
          authorization_endpoint: "https://mastodon.example/oauth/authorize",
          token_endpoint: "https://mastodon.example/oauth/token",
          scopes_supported: ["read", "write"],
          code_challenge_methods_supported: ["S256"]
        })
      end)

      metadata = Hunter.oauth_server_metadata("https://mastodon.example")

      assert metadata["issuer"] == "https://mastodon.example/"
      assert metadata["code_challenge_methods_supported"] == ["S256"]
    end
  end

  describe "userinfo/1" do
    test "fetches OIDC claims with the user token" do
      stub_request(fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/oauth/userinfo"
        assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer 123456"]

        respond_with(conn, %{
          iss: "https://mastodon.example/",
          sub: "https://mastodon.example/@kadaba",
          preferred_username: "kadaba"
        })
      end)

      conn = Hunter.new(base_url: "https://mastodon.example", access_token: "123456")

      assert %{"preferred_username" => "kadaba"} = Hunter.userinfo(conn)
    end
  end
end
