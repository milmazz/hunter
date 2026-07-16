# OAuth Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring Hunter's OAuth surface to Mastodon 4.3/4.4: token revocation, PKCE, client-credentials login, app credential verification, honest `CredentialApplication` handling, RFC 8414 discovery, OIDC userinfo; remove the password grant.

**Architecture:** Every endpoint is a thin function on the `Hunter` facade delegating to `Hunter.Api.Request.request!/4-6` (see spec `docs/superpowers/specs/2026-07-10-oauth-modernization-design.md`). No new modules or entity structs; discovery/userinfo return plain maps (transformer `nil`), revoke uses `:empty` (returns `true`).

**Tech Stack:** Elixir, Req (HTTP), Poison (JSON), Req.Test/Plug stubs for unit tests, docker-composed Mastodon for integration tests.

## Global Constraints

- All endpoint functions live on `Hunter` (`lib/hunter.ex`) — never on entity modules.
- Every network function defaults `base_url \\ "https://mastodon.social"` then applies `base_url = base_url || Config.api_base_url()`, matching `log_in_oauth/3`.
- Unit tests use `Hunter.ReqCase` (`stub_request/1`, `respond_with/2-3`, `read_json_body!/1`) with `api_base_url: "https://mastodon.example"`-style explicit URLs.
- Errors: non-2xx raises `Hunter.Error` via `Request.request!` — no extra handling.
- Run the full unit suite with `mix test` (integration tests are excluded by default) before each commit.

---

### Task 1: `revoke_token/3`

**Files:**
- Modify: `lib/hunter.ex` (insert after `log_in_oauth/3`, which ends near line 1968)
- Create: `test/hunter/oauth_test.exs`

**Interfaces:**
- Consumes: `Request.request!(base_url, :post, path, :empty, payload)` → `true`; `Hunter.Application` struct fields `client_id`, `client_secret`.
- Produces: `Hunter.revoke_token(app :: Hunter.Application.t(), token :: String.t(), base_url :: String.t()) :: true`

- [ ] **Step 1: Write the failing tests**

Create `test/hunter/oauth_test.exs`:

```elixir
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/hunter/oauth_test.exs`
Expected: 2 failures with `UndefinedFunctionError: function Hunter.revoke_token/3 is undefined`

- [ ] **Step 3: Implement `revoke_token/3`**

In `lib/hunter.ex`, immediately after the `log_in_oauth/3` function:

```elixir
@doc """
Revoke an access token

## Parameters

  * `app` - application details (must be the client the token was issued
    to), see: `Hunter.create_app/5`
  * `token` - the access token to revoke
  * `base_url` - API base url, default: `https://mastodon.social`

Returns `true` on success. Raises `Hunter.Error` if the token does not
belong to the given client.
"""
@spec revoke_token(Hunter.Application.t(), String.t(), String.t()) :: true
def revoke_token(%Hunter.Application{} = app, token, base_url \\ "https://mastodon.social") do
  base_url = base_url || Config.api_base_url()

  payload = %{
    client_id: app.client_id,
    client_secret: app.client_secret,
    token: token
  }

  Request.request!(base_url, :post, "/oauth/revoke", :empty, payload)
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/hunter/oauth_test.exs`
Expected: 2 tests, 0 failures. Then `mix test` — full suite green.

- [ ] **Step 5: Commit**

```bash
git add lib/hunter.ex test/hunter/oauth_test.exs
git commit -m "Add revoke_token/3 (POST /oauth/revoke)"
```

---

### Task 2: PKCE helpers — `generate_pkce/0` and `authorization_url/3`

**Files:**
- Modify: `lib/hunter.ex` (insert after `revoke_token/3` from Task 1)
- Modify: `test/hunter/oauth_test.exs`

**Interfaces:**
- Consumes: `Hunter.Application` fields `client_id`, `scopes`, `redirect_uris`, `redirect_uri`.
- Produces:
  - `Hunter.generate_pkce() :: %{code_verifier: String.t(), code_challenge: String.t(), code_challenge_method: String.t()}`
  - `Hunter.authorization_url(app :: Hunter.Application.t(), base_url :: String.t(), opts :: Keyword.t()) :: String.t()`
  - Private `first_redirect_uri(app) :: String.t()` — reused by Task 3.

- [ ] **Step 1: Write the failing tests**

Add to `test/hunter/oauth_test.exs`:

```elixir
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/hunter/oauth_test.exs`
Expected: new tests fail with `UndefinedFunctionError` for `Hunter.generate_pkce/0` and `Hunter.authorization_url/2`.

- [ ] **Step 3: Implement the helpers**

In `lib/hunter.ex`, after `revoke_token/3`:

```elixir
@doc """
Generate a PKCE verifier/challenge pair (RFC 7636, S256)

Returns a map with `code_verifier`, `code_challenge` and
`code_challenge_method`. Pass the challenge params to
`authorization_url/3` and the verifier to `log_in_oauth/4`.
"""
@spec generate_pkce() :: %{
        code_verifier: String.t(),
        code_challenge: String.t(),
        code_challenge_method: String.t()
      }
def generate_pkce do
  verifier = Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)

  %{
    code_verifier: verifier,
    code_challenge: Base.url_encode64(:crypto.hash(:sha256, verifier), padding: false),
    code_challenge_method: "S256"
  }
end

@doc """
Build the URL to send the user to for authorization (`GET /oauth/authorize`)

## Parameters

  * `app` - application details, see: `Hunter.create_app/5`
  * `base_url` - API base url, default: `https://mastodon.social`
  * `opts` - optional params

## Options

  * `redirect_uri` - overrides the app's registered redirect URI
  * `scope` - space-separated scopes, defaults to the app's scopes
  * `code_challenge` / `code_challenge_method` - PKCE params, see
    `generate_pkce/0`
  * `state` - opaque value returned to your redirect URI unchanged
  * `force_login` - forces re-login when `true`
  * `lang` - ISO 639-1 language code for the authorization form

Builds a URL only; performs no request.
"""
@spec authorization_url(Hunter.Application.t(), String.t(), Keyword.t()) :: String.t()
def authorization_url(%Hunter.Application{} = app, base_url \\ "https://mastodon.social", opts \\ []) do
  base_url = base_url || Config.api_base_url()

  query =
    [
      response_type: "code",
      client_id: app.client_id,
      redirect_uri: first_redirect_uri(app),
      scope: default_scope(app)
    ]
    |> Keyword.merge(
      Keyword.take(opts, [
        :redirect_uri,
        :scope,
        :code_challenge,
        :code_challenge_method,
        :state,
        :force_login,
        :lang
      ])
    )
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> URI.encode_query()

  base_url <> "/oauth/authorize?" <> query
end

defp first_redirect_uri(%Hunter.Application{redirect_uris: [uri | _]}), do: uri

defp first_redirect_uri(%Hunter.Application{redirect_uri: uri}) when is_binary(uri), do: uri

# Doorkeeper rejects requests without a redirect_uri matching the
# registration; fall back to create_app's default for stale credentials
defp first_redirect_uri(_app), do: "urn:ietf:wg:oauth:2.0:oob"

defp default_scope(%Hunter.Application{scopes: scopes}) when is_list(scopes) and scopes != [],
  do: Enum.join(scopes, " ")

defp default_scope(_app), do: nil
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/hunter/oauth_test.exs`
Expected: all pass. Then `mix test` — full suite green.

- [ ] **Step 5: Commit**

```bash
git add lib/hunter.ex test/hunter/oauth_test.exs
git commit -m "Add PKCE helpers: generate_pkce/0 and authorization_url/3"
```

---

### Task 3: `code_verifier` option on `log_in_oauth`

**Files:**
- Modify: `lib/hunter.ex:1951-1968` (the `log_in_oauth/3` function)
- Modify: `test/hunter/oauth_test.exs`
- Modify: `test/hunter/client_test.exs` (move the existing `log_in_oauth` describe block into `oauth_test.exs` unchanged, then extend)

**Interfaces:**
- Consumes: `first_redirect_uri/1` from Task 2.
- Produces: `Hunter.log_in_oauth(app, code :: String.t(), base_url :: String.t(), opts :: Keyword.t()) :: Hunter.Client.t()` with `opts[:code_verifier]` forwarded.

- [ ] **Step 1: Move existing coverage and write the failing tests**

Delete the `describe "log_in_oauth/3"` block from `test/hunter/client_test.exs`. In `test/hunter/oauth_test.exs`, add `alias Hunter.Client` directly below `use Hunter.ReqCase, async: true`, then add:

```elixir
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
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/hunter/oauth_test.exs`
Expected: the `code_verifier` test fails with `UndefinedFunctionError: function Hunter.log_in_oauth/4 is undefined`; the `redirect_uris` test fails (current code reads only `redirect_uri`).

- [ ] **Step 3: Update `log_in_oauth`**

Replace the whole `log_in_oauth/3` definition (spec, doc, body) in `lib/hunter.ex` with:

```elixir
@doc """
Retrieve access token via the OAuth authorization-code flow

## Parameters

  * `app` - application details, see: `Hunter.create_app/5` for more details.
  * `oauth_code` - authorization code from the redirect (or the out-of-band
    form)
  * `base_url` - API base url, default: `https://mastodon.social`
  * `opts` - optional params

## Options

  * `code_verifier` - PKCE verifier matching the `code_challenge` sent to
    `authorization_url/3`, see `generate_pkce/0`

"""
@spec log_in_oauth(Hunter.Application.t(), String.t(), String.t(), Keyword.t()) ::
        Hunter.Client.t()
def log_in_oauth(
      %Hunter.Application{} = app,
      oauth_code,
      base_url \\ "https://mastodon.social",
      opts \\ []
    ) do
  base_url = base_url || Config.api_base_url()

  payload = %{
    client_id: app.client_id,
    client_secret: app.client_secret,
    grant_type: "authorization_code",
    code: oauth_code,
    redirect_uri: first_redirect_uri(app)
  }

  payload =
    case Keyword.fetch(opts, :code_verifier) do
      {:ok, verifier} -> Map.put(payload, :code_verifier, verifier)
      :error -> payload
    end

  response = Request.request!(base_url, :post, "/oauth/token", nil, payload)

  %Hunter.Client{base_url: base_url, access_token: response["access_token"]}
end
```

(The `# Doorkeeper rejects...` comment moves with `first_redirect_uri/1` in Task 2 — remove the old inline comment here.)

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/hunter/oauth_test.exs test/hunter/client_test.exs`
Expected: all pass. Then `mix test` — full suite green.

- [ ] **Step 5: Commit**

```bash
git add lib/hunter.ex test/hunter/oauth_test.exs test/hunter/client_test.exs
git commit -m "Support PKCE code_verifier in log_in_oauth"
```

---

### Task 4: `log_in_app/2` (client-credentials grant)

**Files:**
- Modify: `lib/hunter.ex` (insert after `log_in_oauth/4`)
- Modify: `test/hunter/oauth_test.exs`

**Interfaces:**
- Produces: `Hunter.log_in_app(app :: Hunter.Application.t(), base_url :: String.t()) :: Hunter.Client.t()` — used by `verify_app_credentials/1` callers and `register_account/2` callers.

- [ ] **Step 1: Write the failing tests**

Add to `test/hunter/oauth_test.exs`:

```elixir
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/hunter/oauth_test.exs`
Expected: 2 failures with `UndefinedFunctionError: function Hunter.log_in_app/2 is undefined`

- [ ] **Step 3: Implement `log_in_app/2`**

In `lib/hunter.ex`, after `log_in_oauth/4`:

```elixir
@doc """
Retrieve an app-level access token via the client-credentials grant

The returned client can call app-scoped endpoints such as
`verify_app_credentials/1` and `register_account/2`.

## Parameters

  * `app` - application details, see: `Hunter.create_app/5` for more details.
  * `base_url` - API base url, default: `https://mastodon.social`

"""
@spec log_in_app(Hunter.Application.t(), String.t()) :: Hunter.Client.t()
def log_in_app(%Hunter.Application{} = app, base_url \\ "https://mastodon.social") do
  base_url = base_url || Config.api_base_url()

  payload = %{
    client_id: app.client_id,
    client_secret: app.client_secret,
    grant_type: "client_credentials"
  }

  payload =
    case default_scope(app) do
      nil -> payload
      scope -> Map.put(payload, :scope, scope)
    end

  response = Request.request!(base_url, :post, "/oauth/token", nil, payload)

  %Hunter.Client{base_url: base_url, access_token: response["access_token"]}
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/hunter/oauth_test.exs`
Expected: all pass. Then `mix test` — full suite green.

- [ ] **Step 5: Commit**

```bash
git add lib/hunter.ex test/hunter/oauth_test.exs
git commit -m "Add log_in_app/2 client-credentials grant"
```

---

### Task 5: `verify_app_credentials/1`

**Files:**
- Modify: `lib/hunter.ex` (insert after `create_app/5`, in the `## Application` section around line 305-393)
- Modify: `test/hunter/application_test.exs`

**Interfaces:**
- Consumes: `Request.request!(conn, :get, path, :application)` → `Hunter.Application.t()`.
- Produces: `Hunter.verify_app_credentials(conn :: Hunter.Client.t()) :: Hunter.Application.t()`

- [ ] **Step 1: Write the failing test**

Add to `test/hunter/application_test.exs`:

```elixir
test "verify_app_credentials/1 confirms the app token and decodes the app" do
  stub_request(fn conn ->
    assert conn.method == "GET"
    assert conn.request_path == "/api/v1/apps/verify_credentials"
    assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer app-tok"]

    respond_with(conn, %{
      name: "hunter",
      website: nil,
      scopes: ["read", "write"],
      redirect_uris: ["urn:ietf:wg:oauth:2.0:oob"]
    })
  end)

  conn = Hunter.new(base_url: "https://mastodon.example", access_token: "app-tok")

  assert %Hunter.Application{
           name: "hunter",
           client_secret: nil,
           scopes: ["read", "write"],
           redirect_uris: ["urn:ietf:wg:oauth:2.0:oob"]
         } = Hunter.verify_app_credentials(conn)
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/hunter/application_test.exs`
Expected: 1 failure with `UndefinedFunctionError: function Hunter.verify_app_credentials/1 is undefined`

- [ ] **Step 3: Implement `verify_app_credentials/1`**

In `lib/hunter.ex`, after `create_app/5` (before `load_credentials/1`):

```elixir
@doc """
Confirm that the app-level token works

## Parameters

  * `conn` - connection credentials holding an *app-level* access token,
    see `log_in_app/2`

Returns the `Hunter.Application` as the server sees it (never includes
`client_secret`; includes `scopes` and `redirect_uris` since Mastodon 4.3).
"""
@spec verify_app_credentials(Hunter.Client.t()) :: Hunter.Application.t()
def verify_app_credentials(conn) do
  Request.request!(conn, :get, "/api/v1/apps/verify_credentials", :application)
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mix test test/hunter/application_test.exs`
Expected: all pass. Then `mix test` — full suite green.

- [ ] **Step 5: Commit**

```bash
git add lib/hunter.ex test/hunter/application_test.exs
git commit -m "Add verify_app_credentials/1 (GET /api/v1/apps/verify_credentials)"
```

---

### Task 6: `create_app` handles `CredentialApplication` honestly

**Files:**
- Modify: `lib/hunter.ex:342-369` (`create_app/5`)
- Modify: `test/hunter/application_test.exs`

**Interfaces:**
- Consumes: `first_redirect_uri/1` is NOT used here; this task adds its own `List.wrap/1` handling.
- Produces: `Hunter.create_app(name, redirect_uris :: String.t() | [String.t()], scopes, website, options) :: Hunter.Application.t()` — server-returned `scopes`/`redirect_uris`/`redirect_uri` win; requested values only backfill `nil` fields.

- [ ] **Step 1: Write the failing tests**

Add to `test/hunter/application_test.exs`:

```elixir
test "keeps the server's CredentialApplication fields (Mastodon 4.3+)" do
  stub_request(fn conn ->
    assert %{"redirect_uris" => ["https://one.example/cb", "https://two.example/cb"]} =
             read_json_body!(conn)

    respond_with(conn, %{
      id: "1234",
      name: "hunter",
      client_id: "ci",
      client_secret: "cs",
      client_secret_expires_at: 0,
      scopes: ["read"],
      redirect_uris: ["https://one.example/cb", "https://two.example/cb"],
      redirect_uri: "https://one.example/cb\nhttps://two.example/cb"
    })
  end)

  app =
    Hunter.create_app(
      "hunter",
      ["https://one.example/cb", "https://two.example/cb"],
      ["read", "write"],
      nil,
      api_base_url: "https://mastodon.example"
    )

  # server values win over the requested ones
  assert %Hunter.Application{
           client_secret_expires_at: 0,
           scopes: ["read"],
           redirect_uris: ["https://one.example/cb", "https://two.example/cb"],
           redirect_uri: "https://one.example/cb\nhttps://two.example/cb"
         } = app
end

test "backfills scopes and redirect URIs on pre-4.3 responses" do
  stub_request(fn conn ->
    respond_with(conn, %{id: "1234", client_id: "ci", client_secret: "cs"})
  end)

  app =
    Hunter.create_app("hunter", "urn:ietf:wg:oauth:2.0:oob", ["read"], nil,
      api_base_url: "https://mastodon.example"
    )

  assert %Hunter.Application{
           scopes: ["read"],
           redirect_uris: ["urn:ietf:wg:oauth:2.0:oob"],
           redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
         } = app
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/hunter/application_test.exs`
Expected: the 4.3 test fails (current code overwrites `scopes` with `["read", "write"]` and `redirect_uri` with the requested list); the backfill test fails on `redirect_uris` being `nil`.

- [ ] **Step 3: Update `create_app/5`**

Replace the body of `create_app/5` in `lib/hunter.ex` (keep the existing `@doc`; update its `redirect_uri` parameter line and example as shown):

In the `@doc`, change the parameter line to:

```
  * `redirect_uris` - where the user should be redirected after
    authorization; a single URI or a list of URIs (Mastodon 4.3+),
    default: `urn:ietf:wg:oauth:2.0:oob` (no redirect)
```

Then the code:

```elixir
@spec create_app(
        String.t(),
        String.t() | [String.t()],
        [String.t()],
        nil | String.t(),
        Keyword.t()
      ) :: Hunter.Application.t() | no_return
def create_app(
      client_name,
      redirect_uris \\ "urn:ietf:wg:oauth:2.0:oob",
      scopes \\ ["read"],
      website \\ nil,
      options \\ []
    ) do
  {save?, options} = Keyword.pop(options, :save?, false)
  base_url = Keyword.get(options, :api_base_url, Config.api_base_url())

  payload = %{
    client_name: client_name,
    redirect_uris: redirect_uris,
    scopes: Enum.join(scopes, " "),
    website: website
  }

  %Hunter.Application{} =
    app = Request.request!(base_url, :post, "/api/v1/apps", :application, payload)

  # Mastodon 4.3+ returns scopes/redirect_uris itself; only backfill the
  # requested values for older servers that omit them
  requested_uris = List.wrap(redirect_uris)

  app = %Hunter.Application{
    app
    | scopes: app.scopes || scopes,
      redirect_uris: app.redirect_uris || requested_uris,
      redirect_uri: app.redirect_uri || List.first(requested_uris)
  }

  if save?, do: save_credentials(client_name, app)

  app
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/hunter/application_test.exs`
Expected: all pass — including the two pre-existing `create_app` tests (their stub responses omit `scopes`/`redirect_uris`, so backfill preserves their assertions). Then `mix test` — full suite green.

- [ ] **Step 5: Commit**

```bash
git add lib/hunter.ex test/hunter/application_test.exs
git commit -m "create_app: accept multiple redirect URIs, keep server CredentialApplication fields"
```

---

### Task 7: Discovery and OIDC — `oauth_server_metadata/1`, `userinfo/1`

**Files:**
- Modify: `lib/hunter.ex` (insert after `log_in_app/2`)
- Modify: `test/hunter/oauth_test.exs`

**Interfaces:**
- Consumes: transformer `nil` (raw decoded map) — same as `register_account/2`.
- Produces: `Hunter.oauth_server_metadata(base_url :: String.t()) :: map`; `Hunter.userinfo(conn :: Hunter.Client.t()) :: map`

- [ ] **Step 1: Write the failing tests**

Add to `test/hunter/oauth_test.exs`:

```elixir
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/hunter/oauth_test.exs`
Expected: 2 failures with `UndefinedFunctionError`.

- [ ] **Step 3: Implement both functions**

In `lib/hunter.ex`, after `log_in_app/2`:

```elixir
@doc """
Fetch the instance's OAuth server metadata (RFC 8414)

Use this to discover supported scopes, grant types and endpoints instead
of hardcoding them. Available since Mastodon 4.3. Does not require
authentication.

## Parameters

  * `base_url` - API base url, default: `https://mastodon.social`

Returns the decoded metadata map (`"issuer"`, `"authorization_endpoint"`,
`"token_endpoint"`, `"scopes_supported"`,
`"code_challenge_methods_supported"`, ...).
"""
@spec oauth_server_metadata(String.t()) :: map
def oauth_server_metadata(base_url \\ "https://mastodon.social") do
  base_url = base_url || Config.api_base_url()

  Request.request!(base_url, :get, "/.well-known/oauth-authorization-server", nil)
end

@doc """
Fetch OIDC-style claims about the authenticated user

Available since Mastodon 4.4; the token must carry the `profile` (or
`read`) scope.

## Parameters

  * `conn` - connection credentials

Returns the decoded claims map (`"iss"`, `"sub"`, `"name"`,
`"preferred_username"`, ...).
"""
@spec userinfo(Hunter.Client.t()) :: map
def userinfo(conn) do
  Request.request!(conn, :get, "/oauth/userinfo", nil)
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/hunter/oauth_test.exs`
Expected: all pass. Then `mix test` — full suite green.

- [ ] **Step 5: Commit**

```bash
git add lib/hunter.ex test/hunter/oauth_test.exs
git commit -m "Add oauth_server_metadata/1 and userinfo/1"
```

---

### Task 8: Remove `log_in/4`; update README and CHANGELOG

**Files:**
- Modify: `lib/hunter.ex:1901-1941` (delete `log_in/4` — doc, spec, body)
- Modify: `test/hunter/client_test.exs` (delete the `describe "log_in/4"` block and the now-unused `@app` attribute if nothing else references it)
- Modify: `README.md:60-78` (the "Acquire an access token" section)
- Modify: `CHANGELOG.md` (Unreleased section)

**Interfaces:**
- Consumes: everything from Tasks 1-7 (README documents the new flow).
- Produces: no `Hunter.log_in/4`; README shows the PKCE flow.

- [ ] **Step 1: Delete `log_in/4` and its tests**

Remove from `lib/hunter.ex` the whole block from `@doc """ Retrieve access token` through the end of `log_in/4` (currently lines 1901-1941). Remove the `describe "log_in/4"` block from `test/hunter/client_test.exs`; if `@app` is now unused in that file, remove it too.

- [ ] **Step 2: Verify the suite still passes**

Run: `mix test`
Expected: green, no warnings about `Hunter.log_in/4`.
Also run: `grep -rn "log_in(" lib README.md` — the only hits should be `log_in_oauth(` / `log_in_app(`. (`test/integration/mastodon_test.exs` still references it; Task 9 fixes that.)

- [ ] **Step 3: Rewrite the README auth section**

Replace README.md lines 60-78 (from `### Acquire an access token` through `Now you can use \`conn\` in any API request.`) with:

````markdown
### Acquire an access token

Mastodon uses the OAuth authorization-code flow, ideally with PKCE
(Mastodon 4.3+). Generate a challenge, send the user to the
authorization page, then exchange the code they bring back:

```elixir
iex> pkce = Hunter.generate_pkce()
iex> Hunter.authorization_url(app, "https://example.com",
...>   code_challenge: pkce.code_challenge,
...>   code_challenge_method: pkce.code_challenge_method)
"https://example.com/oauth/authorize?response_type=code&client_id=..."
# the user authorizes there and receives a code
iex> conn = Hunter.log_in_oauth(app, "123456code", "https://example.com",
...>   code_verifier: pkce.code_verifier)
%Hunter.Client{base_url: "https://example.com",
 access_token: "123456"}
```

For app-level endpoints (registering accounts, verifying the app), use
the client-credentials grant:

```elixir
iex> app_conn = Hunter.log_in_app(app, "https://example.com")
%Hunter.Client{base_url: "https://example.com",
 access_token: "654321"}
iex> Hunter.verify_app_credentials(app_conn)
%Hunter.Application{name: "hunter", ...}
```

Tokens can be revoked when you are done with them:

```elixir
iex> Hunter.revoke_token(app, conn.access_token, "https://example.com")
true
```

Now you can use `conn` in any API request.
````

- [ ] **Step 4: Update the CHANGELOG**

In `CHANGELOG.md` under `## Unreleased`, add a Breaking changes section above Features, and extend Features:

```markdown
  * Breaking changes
    - Remove `Hunter.log_in/4`: the OAuth password grant is no longer a
      documented Mastodon flow. Use `Hunter.log_in_oauth/4`
      (authorization code + PKCE) or `Hunter.log_in_app/2`
      (client credentials) instead ([#126])

  * Features
    - OAuth modernization ([#126]): `revoke_token/3`, PKCE support
      (`generate_pkce/0`, `authorization_url/3`, and a `code_verifier`
      option on `log_in_oauth/4`), `log_in_app/2` (client-credentials
      grant), `verify_app_credentials/1`, `oauth_server_metadata/1`
      (RFC 8414) and `userinfo/1` (OIDC claims), all on `Hunter`.
      `create_app/5` now accepts a list of redirect URIs and preserves
      the server's `CredentialApplication` fields instead of
      overwriting them
```

(Keep the existing `#124` Features bullet; add the new bullet alongside it.) The CHANGELOG uses reference-style links — add this line to the link block at the bottom of the file (around line 145), keeping it grouped with the other issue links:

```markdown
[#126]: https://github.com/milmazz/hunter/issues/126
```

- [ ] **Step 5: Run the suite and commit**

Run: `mix test`
Expected: green.

```bash
git add lib/hunter.ex test/hunter/client_test.exs README.md CHANGELOG.md
git commit -m "Remove the password grant (log_in/4)"
```

---

### Task 9: Integration coverage — provisioning script and tests

**Files:**
- Modify: `scripts/ci/setup_mastodon.sh`
- Modify: `test/support/integration_case.ex`
- Modify: `test/integration/mastodon_test.exs`

**Interfaces:**
- Consumes: all public functions from Tasks 1-8.
- Produces: env vars `HUNTER_OAUTH_PKCE_CODE`, `HUNTER_OAUTH_PKCE_VERIFIER`; integration context keys `pkce_code`, `pkce_verifier`.

- [ ] **Step 1: Mint a PKCE-bound grant in `setup_mastodon.sh`**

In `scripts/ci/setup_mastodon.sh`:

(a) Change the `mint_token` scopes so `userinfo` works (two places inside the heredoc), from `'read write follow push'` to `'read write follow push profile'`, and the refresh guard from `unless app.scopes.to_s.include?('push')` to `unless app.scopes.to_s.include?('profile')`. Update the comment to `# profile scope added later; refresh pre-existing app/token rows in place`. Do the same for the token refresh condition — it already compares `token.scopes` to `app.scopes`, so no change needed there.

(b) After the existing `OAUTH_PROVISION` block (line ~113), add:

```bash
# A PKCE-bound grant: the verifier is generated here, its S256 challenge
# stored on the grant, and both travel to the test suite via env vars.
PKCE_VERIFIER=$(openssl rand -base64 32 | tr '+/' '-_' | tr -d '=')
PKCE_CHALLENGE=$(printf %s "$PKCE_VERIFIER" | openssl dgst -sha256 -binary | base64 | tr '+/' '-_' | tr -d '=')

PKCE_CODE=$($COMPOSE exec -T -e PKCE_CHALLENGE="$PKCE_CHALLENGE" web bin/rails runner "
  app = Doorkeeper::Application.find_by!(name: 'hunter-ci-oauth')
  user = User.find_by!(email: 'kadaba@example.com')
  grant = Doorkeeper::AccessGrant.create!(
    application_id: app.id, resource_owner_id: user.id,
    redirect_uri: app.redirect_uri, expires_in: 86_400, scopes: app.scopes.to_s,
    code_challenge: ENV.fetch('PKCE_CHALLENGE'), code_challenge_method: 'S256'
  )
  puts (grant.respond_to?(:plaintext_token) && grant.plaintext_token) || grant.token
" | tr -d '[:space:]')
```

(c) Add to the `$HUNTER_ENV` heredoc:

```bash
export HUNTER_OAUTH_PKCE_CODE=$PKCE_CODE
export HUNTER_OAUTH_PKCE_VERIFIER=$PKCE_VERIFIER
```

(d) Add to the `$GITHUB_ENV` block:

```bash
    echo "HUNTER_OAUTH_PKCE_CODE=$PKCE_CODE"
    echo "HUNTER_OAUTH_PKCE_VERIFIER=$PKCE_VERIFIER"
```

- [ ] **Step 2: Expose the new env vars in `Hunter.IntegrationCase`**

In `test/support/integration_case.ex` `setup_all`, after the `oauth_code` fetch add:

```elixir
pkce_code = fetch_env!("HUNTER_OAUTH_PKCE_CODE")
pkce_verifier = fetch_env!("HUNTER_OAUTH_PKCE_VERIFIER")
```

and extend the returned context:

```elixir
     oauth_code: oauth_code,
     pkce_code: pkce_code,
     pkce_verifier: pkce_verifier}
```

Also update the `@moduledoc` env list to mention `HUNTER_OAUTH_PKCE_CODE` and `HUNTER_OAUTH_PKCE_VERIFIER`.

- [ ] **Step 3: Rework and add integration tests**

In `test/integration/mastodon_test.exs`, replace the whole `"README auth flow: create_app + log_in yields a token that can write"` test (lines 433-455) with:

```elixir
test "app credentials flow: create_app + log_in_app + verify_app_credentials", %{conn: conn} do
  app_name = "hunter-auth-#{System.unique_integer([:positive])}"

  app =
    Hunter.create_app(app_name, "urn:ietf:wg:oauth:2.0:oob", ["read", "write"], nil,
      api_base_url: conn.base_url
    )

  assert %Hunter.Application{scopes: ["read", "write"]} = app

  app_conn = Hunter.log_in_app(app, conn.base_url)
  assert %Hunter.Client{access_token: token} = app_conn
  assert is_binary(token)

  assert %Hunter.Application{name: ^app_name} = Hunter.verify_app_credentials(app_conn)
end

test "revoked app tokens stop working", %{conn: conn} do
  app =
    Hunter.create_app(
      "hunter-revoke-#{System.unique_integer([:positive])}",
      "urn:ietf:wg:oauth:2.0:oob",
      ["read"],
      nil,
      api_base_url: conn.base_url
    )

  app_conn = Hunter.log_in_app(app, conn.base_url)
  assert %Hunter.Application{} = Hunter.verify_app_credentials(app_conn)

  assert Hunter.revoke_token(app, app_conn.access_token, conn.base_url) == true

  assert_raise Hunter.Error, fn ->
    Hunter.verify_app_credentials(app_conn)
  end
end
```

After the existing `"OAuth authorization-code flow"` test (ends line 486), add:

```elixir
test "PKCE authorization-code flow: verifier round-trips", %{
  conn: conn,
  oauth_client_id: client_id,
  oauth_client_secret: client_secret,
  pkce_code: code,
  pkce_verifier: verifier
} do
  app = %Hunter.Application{
    client_id: client_id,
    client_secret: client_secret,
    scopes: ["read", "write"],
    redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
  }

  logged_in = Hunter.log_in_oauth(app, code, conn.base_url, code_verifier: verifier)
  assert %Hunter.Client{access_token: token} = logged_in
  assert is_binary(token)

  %Status{id: id} = Hunter.create_status(logged_in, "pkce flow works #hunterci")
  on_exit(fn -> destroy_quietly(logged_in, id) end)
  Hunter.destroy_status(logged_in, id)
end

test "oauth_server_metadata returns RFC 8414 metadata", %{conn: conn} do
  metadata = Hunter.oauth_server_metadata(conn.base_url)

  assert is_map(metadata)
  assert is_binary(metadata["issuer"])
  assert "S256" in metadata["code_challenge_methods_supported"]
end

test "userinfo returns OIDC claims for the token's user", %{conn: conn} do
  claims = Hunter.userinfo(conn)

  assert is_binary(claims["sub"])
  assert claims["preferred_username"] == "hunter"
end
```

- [ ] **Step 4: Verify**

Run: `mix test` — unit suite green (integration tests are tagged out).

If a local Docker daemon is available, run the integration suite:

```bash
./scripts/ci/setup_mastodon.sh
source scripts/ci/.env.hunter
mix test --only integration
```

Expected: all integration tests pass. If Docker is not available, state that the integration run is pending CI — do not claim it passed.

- [ ] **Step 5: Commit**

```bash
git add scripts/ci/setup_mastodon.sh test/support/integration_case.ex test/integration/mastodon_test.exs
git commit -m "Integration coverage for PKCE, revocation, app credentials, discovery"
```
