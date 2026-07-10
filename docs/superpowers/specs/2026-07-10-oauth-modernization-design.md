# OAuth modernization: PKCE, revocation, app credentials, discovery

Issue: #126. Part of the Mastodon 4.6 API parity effort. Closes the last
auth item left open by #118 (password grant).

## Goal

Bring Hunter's OAuth surface from its 2017 snapshot up to Mastodon
4.3/4.4: token revocation, PKCE on the authorization-code flow, an
app-level (client-credentials) login, app credential verification, honest
`CredentialApplication` handling, and the discovery/OIDC endpoints.
Remove the undocumented password grant. All ship in a single PR.

## Approach

Everything stays on the `Hunter` facade (per #138); each endpoint is a
thin function over `Hunter.Api.Request.request!/4-6`. No new modules and
no new entity structs: `verify_app_credentials` reuses
`Hunter.Application` (which already carries the 4.3/4.4 fields), while
the RFC 8414 metadata and OIDC userinfo responses are returned as plain
maps — they are open-ended standard formats, not Mastodon entities, and
a struct would go stale as servers add fields.

## Token lifecycle

### `revoke_token(app, token, base_url \\ "https://mastodon.social")`

`POST /oauth/revoke` with `client_id`, `client_secret`, `token`.
Transformer `:empty`; returns `true`. Raises `Hunter.Error` on failure
(Mastodon returns 403 `unauthorized_client` when the token does not
belong to the client).

### PKCE on the code exchange

`log_in_oauth/3` gains a trailing options list:

```elixir
@spec log_in_oauth(Hunter.Application.t(), String.t(), String.t(), Keyword.t()) ::
        Hunter.Client.t()
def log_in_oauth(app, code, base_url \\ "https://mastodon.social", opts \\ [])
```

When `opts[:code_verifier]` is present it is forwarded in the
`POST /oauth/token` payload. Existing 2- and 3-arity calls are unchanged.

### `log_in_app(app, base_url \\ "https://mastodon.social")`

`POST /oauth/token` with `grant_type=client_credentials` (plus
`client_id`, `client_secret`, `scope` from `app.scopes` when set).
Returns a `Hunter.Client` holding the app-level token. This is one step
beyond the issue checklist, but without it `verify_app_credentials/1`
and the existing `register_account/2` cannot be driven through Hunter
at all.

### Remove `log_in/4`

The password grant is no longer a documented Mastodon flow. The function,
its spec, its unit tests, and the README section that demonstrates it are
deleted. Breaking change, recorded in the CHANGELOG.

## PKCE helpers (pure, no HTTP)

### `generate_pkce/0`

Returns `%{code_verifier: verifier, code_challenge: challenge,
code_challenge_method: "S256"}` where `verifier` is 32 bytes from
`:crypto.strong_rand_bytes/1` encoded `Base.url_encode64(padding: false)`
(43 chars) and `challenge` is the unpadded base64url SHA-256 of the
verifier, per RFC 7636.

### `authorization_url(app, base_url \\ "https://mastodon.social", opts \\ [])`

Builds the `GET /oauth/authorize` URL the caller sends the user to:
`response_type=code`, `client_id` from the app, `redirect_uri` from
`opts` or the app's first registered URI (`redirect_uris` list head,
then `redirect_uri`, then the oob URN), `scope` from `opts` or
`app.scopes` joined with spaces. Optional passthrough params:
`code_challenge`, `code_challenge_method`, `state`, `force_login`,
`lang`. Returns the URL string; performs no request.

## App credentials

### `verify_app_credentials(conn)`

`GET /api/v1/apps/verify_credentials` with the app-level bearer token.
Transformer `:application`; returns `Hunter.Application` (the server
omits `client_secret`; since 4.3 it includes `scopes` and
`redirect_uris`).

### `create_app` handles `CredentialApplication` honestly

- `redirect_uris` accepts a `String.t` **or** `[String.t]` and is
  forwarded as given (Mastodon accepts an array since 4.3).
- The server response is no longer clobbered: today `create_app`
  overwrites `scopes` with its input and `redirect_uri` with its input.
  Instead, server-returned `scopes`/`redirect_uris`/`redirect_uri` win,
  and the requested values are only backfilled when the server returned
  none (pre-4.3 servers). The `redirect_uri` backfill uses the first
  requested URI so persisted credentials keep working with
  `log_in_oauth`.
- `Hunter.Application` already models `client_secret_expires_at` and
  `redirect_uris`, and already omits the deprecated `vapid_key` — no
  struct changes.

## Discovery / OIDC

### `oauth_server_metadata(base_url \\ "https://mastodon.social")`

`GET /.well-known/oauth-authorization-server` (RFC 8414, Mastodon 4.3).
Unauthenticated; transformer `nil`; returns the decoded map
(`issuer`, `authorization_endpoint`, `token_endpoint`,
`scopes_supported`, `code_challenge_methods_supported`, ...).

### `userinfo(conn)`

`GET /oauth/userinfo` (Mastodon 4.4) with a user-level token carrying
the `profile` (or `read`) scope. Transformer `nil`; returns the decoded
OIDC claims map (`iss`, `sub`, `name`, `preferred_username`, ...).

## Testing

### Unit (`Hunter.ReqCase` / `Req.Test` stubs)

New `test/hunter/oauth_test.exs`:

- `revoke_token/3` — POST `/oauth/revoke`, body carries
  `client_id`/`client_secret`/`token`, returns `true`; 403 raises.
- `log_in_oauth/4` — payload includes `code_verifier` when given and
  omits it otherwise.
- `log_in_app/2` — `grant_type=client_credentials` payload; returns a
  `Hunter.Client` with the token.
- `generate_pkce/0` — verifier is 43 chars of the base64url alphabet,
  unique across calls; challenge equals the recomputed unpadded
  base64url SHA-256 of the returned verifier.
- `authorization_url/3` — asserts the exact query string incl.
  challenge params; defaulting of scope/redirect_uri from the app.
- `oauth_server_metadata/1` and `userinfo/1` — path, auth header
  presence/absence, map passthrough.

`test/hunter/application_test.exs` gains:

- `verify_app_credentials/1` — GET path, bearer header, decoded
  `Hunter.Application`.
- a 4.3-shaped `CredentialApplication` response for `create_app`
  (list `redirect_uris`, `client_secret_expires_at`) asserting the
  server values survive and nothing is clobbered.
- a pre-4.3-shaped response asserting the backfill.

`log_in/4` tests in `test/hunter/client_test.exs` are removed.

### Integration (`test/integration/mastodon_test.exs`)

`scripts/ci/setup_mastodon.sh` additionally mints a PKCE-bound grant:
a fixed `code_verifier` is generated in the script, its S256 challenge
stored on a second `Doorkeeper::AccessGrant`
(`code_challenge`/`code_challenge_method` columns), and
`HUNTER_OAUTH_PKCE_CODE`/`HUNTER_OAUTH_PKCE_VERIFIER` are exported.
New/updated tests:

- PKCE exchange: `log_in_oauth(app, code, base_url, code_verifier: v)`
  yields a working client.
- Revoke: revoke the token from the plain oauth flow, then assert an
  authenticated call raises `Hunter.Error`.
- App flow: `log_in_app` + `verify_app_credentials` round-trip.
- `oauth_server_metadata/1` returns a map with the instance `issuer`.
- `userinfo/1` returns claims for the token's user.
- The "README auth flow" test drops `log_in` and instead exercises
  `create_app` → `log_in_app` → `verify_app_credentials`.

## Docs

- README auth section rewritten around authorization-code + PKCE
  (`create_app` → `generate_pkce` → `authorization_url` → user pastes
  code → `log_in_oauth(..., code_verifier: ...)`), with `log_in_app`
  for app-level calls; the password-grant example is removed.
- CHANGELOG: additions listed; `log_in/4` removal called out as
  breaking.

## Out of scope

- A `Hunter.Token` entity (login functions keep returning
  `Hunter.Client`).
- Refresh-token support (Mastodon does not issue refresh tokens).
- `Hunter.ServerMetadata`/`Hunter.UserInfo` structs.
- Any other parity issue (#120–#128).
