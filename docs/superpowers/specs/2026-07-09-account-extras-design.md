# Account extras: lookup, familiar followers, notes, endorsements, registration

Issue: #124. Part of the Mastodon 4.6 API parity effort. Depends on #119
(closed) which added `Account.fields`, the `Relationship` note/endorsed
fields, and the `FeaturedTag` entity.

## Goal

Expose the account-level endpoints Mastodon added since 2.4 that Hunter
does not yet surface. Eleven endpoints across four groups: lookup/fetch,
registration, relationship extras, and endorsements. All ship in a single
PR.

## Approach

Each endpoint is a thin function on the `Hunter` module delegating to
`Hunter.Api.Request.request!/4-6`, exactly like the existing account
functions (`account/2`, `followers/3`, `relationships/2`, `follow/2`).
The response is decoded by a `Hunter.Api.Transformer` target atom into an
existing entity struct.

Ten of the eleven endpoints reuse existing entities (`Account`,
`Relationship`, `FeaturedTag`). Only `familiar_followers` needs a new
entity because its response is a distinct shape.

## New entity

`Hunter.FamiliarFollowers` (`lib/hunter/familiar_followers.ex`):

- `id` — `String.t` — the account id these familiar followers relate to
- `accounts` — `[Hunter.Account.t]` — accounts you follow that also
  follow that account

Standard entity module: `@type t`, `@derive [Poison.Encoder]`,
`defstruct`, moduledoc with a `## Fields` list, matching the style of
`Hunter.FeaturedTag`.

New transformer clause in `Hunter.Api.Transformer`:

```elixir
def transform(body, :familiar_followers),
  do: Poison.decode!(body, as: [%Hunter.FamiliarFollowers{accounts: [account_nested_struct()]}])
```

## Endpoints (functions on `Hunter`)

| Function | HTTP / Path | Transformer | Returns |
|----------|-------------|-------------|---------|
| `lookup_account(conn, acct)` | GET `/api/v1/accounts/lookup?acct=` | `:account` | `Account.t` |
| `accounts_by_ids(conn, ids)` | GET `/api/v1/accounts?id[]=` | `:accounts` | `[Account.t]` |
| `familiar_followers(conn, ids)` | GET `/api/v1/accounts/familiar_followers?id[]=` | `:familiar_followers` | `[FamiliarFollowers.t]` |
| `account_featured_tags(conn, id)` | GET `/api/v1/accounts/:id/featured_tags` | `:featured_tags` | `[FeaturedTag.t]` |
| `register_account(conn, params)` | POST `/api/v1/accounts` | `nil` (raw) | `Hunter.Client.t` |
| `set_account_note(conn, id, comment)` | POST `/api/v1/accounts/:id/note` `{comment}` | `:relationship` | `Relationship.t` |
| `remove_from_followers(conn, id)` | POST `/api/v1/accounts/:id/remove_from_followers` | `:relationship` | `Relationship.t` |
| `endorsements(conn, opts \\ [])` | GET `/api/v1/endorsements` | `:accounts` | `[Account.t]` |
| `endorse(conn, id)` | POST `/api/v1/accounts/:id/endorse` | `:relationship` | `Relationship.t` |
| `unendorse(conn, id)` | POST `/api/v1/accounts/:id/unendorse` | `:relationship` | `Relationship.t` |
| `account_endorsements(conn, id, opts \\ [])` | GET `/api/v1/accounts/:id/endorsements` | `:accounts` | `[Account.t]` |

### Naming rationale

- `accounts_by_ids` parallels the existing `statuses_by_ids/2`.
- `endorse`/`unendorse` parallel `follow`/`unfollow`. The issue notes the
  older `pin`/`unpin` account variants are deprecated (4.4) — not
  implemented. The existing `pin`/`unpin` functions on `Hunter` act on
  *statuses*, so there is no collision.
- `endorsements/2` (your featured accounts, 2.5) and
  `account_endorsements/3` (a given account's featured accounts, 4.4) are
  distinct endpoints and get distinct names.

### List params

`ids`-taking functions (`accounts_by_ids`, `familiar_followers`) pass
`%{id: ids}` — `Hunter.Api.Request.encode_params/1` already expands a list
value into repeated `id[]=` params (see `relationships/2`).

Pagination functions (`endorsements`, `account_endorsements`) take an
options keyword forwarded verbatim (`max_id`, `since_id`, `limit`).

### Registration detail

`register_account/2` mirrors `log_in/*`: the caller passes a
`Hunter.Client` carrying the *app-level* access token. We POST the
registration params (`username`, `email`, `password`, `agreement`,
`locale`, and optional `reason`) with the transformer set to `nil` so we
get the raw decoded Token map, then return
`%Hunter.Client{base_url: conn.base_url, access_token: response["access_token"]}`.
No `Token` entity is introduced.

## Testing

Add one test per endpoint in `test/hunter/account_test.exs` using the
existing `Hunter.ReqCase` harness (`stub_request/1`,
`respond_with_fixture/2-3`, `read_json_body!/1`), asserting method, path,
query string / body, and the decoded struct.

- Reuse `account.json`, `relationship.json`, `featured_tag.json`.
- Add `test/fixtures/familiar_followers.json` (array of one
  `{id, accounts: [account]}`).
- `register_account` test stubs POST `/api/v1/accounts` returning a Token
  JSON (`access_token`, `token_type`, `scope`, `created_at`) and asserts a
  `%Hunter.Client{}` with the token comes back, and that the request
  carried the app bearer token.
- Add a `:familiar_followers` case to `test/hunter/api/transformer_test.exs`.

## Out of scope

- A `Hunter.Token` entity (registration returns a `Hunter.Client`).
- The deprecated account `pin`/`unpin` endorsement endpoints.
- Any other parity issue (#118, #120–#128).
