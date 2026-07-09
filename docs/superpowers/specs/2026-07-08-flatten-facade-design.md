# Flatten the facade: one public module, one transport module

**Date:** 2026-07-08
**Status:** Approved

## Problem

Every endpoint is implemented three times across three layers:

1. `Hunter.followers/3` — full docs + `@spec` + `defdelegate` (`lib/hunter.ex`)
2. `Hunter.Account.followers/3` — the same docs + `@spec` again, plus a
   one-line call into the client (`lib/hunter/account.ex`)
3. `Hunter.Api.HTTPClient.followers/3` — the actual three-line
   implementation (`lib/hunter/api/http_client.ex`)

Consequences: two levels of indirection before the real implementation,
duplicated documentation that has already started to drift between the
facade and entity copies, and duplicated unit-test surface. The entity
functions are textbook shallow pass-through methods (Ousterhout, *A
Philosophy of Software Design*): same signature, same semantics, no added
abstraction.

## Decision

Remove the middle layer entirely and merge the bottom two.

- **`Hunter`** becomes the single deep public module: docs, specs, and the
  real implementation bodies live only here. Single file (`lib/hunter.ex`,
  ~1700 lines of mostly docs); each body is a short pipe into the transport.
- **Entity modules** become pure data definitions: `defstruct`, `@type t`,
  and field documentation. No HTTP functions, no `HTTPClient` alias.
- **`Hunter.Api.Request`** is the single transport module. It absorbs
  `HTTPClient`'s private helpers (`request!/5`, `get_headers/1`,
  `process_url/2`) and exposes a conn-aware entry point. **The `Request`
  module name and test file survive; `Hunter.Api.HTTPClient` is deleted.**
- **`Hunter.Api.Transformer`** is unchanged.

This is a breaking change (removal of every `Hunter.<Entity>.<endpoint>/n`
function). Accepted: the library is mid-revamp for Mastodon 4.6 parity and
has shipped several breaking releases already. No `@deprecated` shims —
hard removal with a CHANGELOG migration table and a bump to **0.7.0**.

## Design

### Transport: `Hunter.Api.Request.request!/5`

```elixir
@spec request!(
        Hunter.Client.t() | String.t(),
        atom,
        String.t(),
        atom | nil,
        Keyword.t() | map | {:form_multipart, list}
      ) :: term
def request!(conn_or_base_url, method, path, to, payload \\ [])
```

Responsibilities, in order:

1. Join `path` onto the base URL (from `%Hunter.Client{base_url: _}` or a
   bare base-URL string) — replaces `process_url/2`.
2. Build headers: `Bearer` auth token when given a `%Hunter.Client{}`,
   none for a bare base URL — replaces `get_headers/1`.
3. Call the existing low-level `Req` plumbing (params encoding, multipart,
   JSON body, response handling) already in `Request`.
4. On success, run `Hunter.Api.Transformer.transform(body, to)`.
5. On failure, `raise Hunter.Error, reason: reason`.

The existing `Request.request/5` / `Request.request!/5` (method-first,
URL-string) low-level functions are subsumed: their plumbing becomes
private helpers of the new `request!/5`. The public surface of the module
is the conn-aware `request!/5` only.

### Facade: `Hunter`

Typical endpoint after the change:

```elixir
@doc """
Get a list of followers
...
"""
@spec followers(Hunter.Client.t(), String.t() | non_neg_integer, Keyword.t()) ::
        [Hunter.Account.t()]
def followers(conn, id, options \\ []) do
  Request.request!(conn, :get, "/api/v1/accounts/#{id}/followers", :accounts, options)
end
```

Functions with real logic move their full bodies (and private helpers)
into `Hunter`:

- `create_app/5` — payload build, `save?: true` handling, and the private
  `save_credentials/2`; `load_credentials/1` moves too.
- `log_in/4` and `log_in_oauth/3` — payload build + `%Hunter.Client{}`
  construction (currently split between `Hunter.Client` and `HTTPClient`).
- `search_account/2` — required-`:q` opts building.
- `upload_media/3` — multipart parts construction.
- `new/1` and `user_agent/0` — move from `Hunter.Client`, which becomes a
  pure struct like every other entity.

### Entity modules

Keep: `@moduledoc` (entity + field docs), `@type t`, `@derive`,
`defstruct`. Remove: every endpoint function, `alias Hunter.Api.HTTPClient`.
Affected modules (the ones that alias `HTTPClient` today): `Account`,
`Application`, `Attachment`, `Client`, `Context`, `Domain`, `Instance`,
`List`, `Notification`, `Poll`, `Relationship`, `Report`, `Result`,
`Status`, `WebPushSubscription`.

### Tests

- Per-domain test files (`test/hunter/account_test.exs`, …) stay in place;
  the module under test changes from the entity to `Hunter`. Req.Test
  stubs and fixtures are unchanged.
- `test/hunter/api/request_test.exs` gains coverage for the conn-aware
  `request!/5`: URL join, auth header from conn vs bare base URL,
  transformer dispatch, `Hunter.Error` on failure.
- `test/integration/mastodon_test.exs` updated to call `Hunter.*` where it
  doesn't already.
- Net effect: one call path, one place to test it.

### Docs & release

- CHANGELOG: breaking-changes section with a migration table
  (`Hunter.Account.followers/3` → `Hunter.followers/3`, one row per
  removed module).
- README examples audited for entity-module calls.
- Version bump to 0.7.0.

## Delivery: two stacked PRs

1. **PR 1 — transport merge (non-breaking).** `Request` absorbs
   `HTTPClient`'s helpers and grows the conn-aware `request!/5`;
   `HTTPClient`'s endpoint functions keep their signatures but their
   bodies become single calls to `Request.request!/5`; suite stays green
   with no public API change.
2. **PR 2 — the breaking flatten.** Endpoint bodies move into `Hunter`,
   `HTTPClient` is deleted, entity modules stripped to structs, tests
   retargeted, CHANGELOG + 0.7.0.

## Alternatives considered

- **Option 1 — promote `HTTPClient` bodies into entity modules.** Removes
  one hop but keeps the facade/entity doc duplication and the doubled test
  surface. Rejected: solves half the problem.
- **`@deprecated` shims for one release.** Rejected: the revamp is already
  breaking, and shims would preserve the exact duplication being removed.
- **Per-domain internal modules under the facade.** Rejected: reintroduces
  one-hop delegation and doc-drift risk to save file length.
