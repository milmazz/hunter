# Auth Fixes Design: Token Scopes (#100) + access_token Rename (#101)

**Date:** 2026-07-07
**Status:** Approved
**Related:** [issue #100](https://github.com/milmazz/hunter/issues/100),
[issue #101](https://github.com/milmazz/hunter/issues/101)

## Goal

Make `log_in/4` request the scopes the app was registered with, so tokens can
actually write (#100), and rename `Hunter.Client.bearer_token` to
`access_token` for ecosystem consistency (#101). One branch (`auth-fixes` off
`main`), one PR, shipping in the 0.6.0 breaking window.

## Root cause of #100 (diagnosed live, 2026-07-07)

`Hunter.Api.HTTPClient.log_in/4` omits `scope` from the `/oauth/token`
password-grant payload. Doorkeeper then grants Mastodon's **default scope,
`read`**, regardless of the app's registered scopes. Reproduced against a
local Mastodon v4.3.8: token request without `scope` → `granted scope: read`
→ `POST /api/v1/statuses` returns exactly the issue's error ("This action is
outside the authorized scopes"). Same request with
`scope: "read write follow"` → write succeeds.

Constraint discovered: `Hunter.Application` does not store the scopes it was
created with, so `log_in` has nothing to re-request today.

## Decisions (user-approved 2026-07-07)

1. **#100 fix shape:** store scopes on `Hunter.Application` (new `scopes`
   field, persisted by `save?: true`); `log_in` sends them. Not an explicit
   `log_in` argument; not hardcoded scopes.
2. **#101 shape:** hard rename, no compatibility shim. Compile-time breakage
   is loud and documented.
3. Single PR; rename lands first so the #100 code is written against the new
   field name.
4. `log_in_oauth`'s suspected missing `redirect_uri` is out of scope — file a
   separate issue instead of widening this PR (verification requires a
   browser authorization dance).

## Part 0: restore the lost CHANGELOG entry

The rebase-merge of PR #109 dropped its final commit (`cb80130`). First
commit of this branch restores the Unreleased "Bug fixes" bullet for #74
(GET/DELETE options as query params) with its `[#74]` link reference.

## Part 1: #101 hard rename

- `Hunter.Client`: `defstruct [:base_url, :access_token]`, `@type t`, and
  moduledoc/`new/1` docs updated.
- `Hunter.Api.HTTPClient`: `get_headers/1` matches
  `%Hunter.Client{access_token: token}`; `log_in/4` and `log_in_oauth/3`
  build `%Hunter.Client{base_url: base_url, access_token: …}`.
- All test files constructing `Hunter.Client.new(bearer_token: …)` switch to
  `access_token:` (≈12 unit test files plus
  `test/support/integration_case.ex`).
- README examples updated (`grep -rn bearer_token` must come up empty
  repo-wide except CHANGELOG history).
- CHANGELOG breaking entry: rename, with the one-line migration
  (`bearer_token:` → `access_token:`).

## Part 2: #100 fix

- `Hunter.Application` gains `scopes` (list of `String.t()`, default `nil`):
  struct, `@type`, field docs.
- `HTTPClient.create_app/5` puts the **requested** scopes list into the
  returned struct after decoding (the v1 apps response cannot be trusted to
  echo scopes across server versions). Persisted credentials
  (`save?: true` → Poison-encoded file) therefore include scopes; old files
  load with `scopes: nil`.
- `HTTPClient.log_in/4` payload gains `scope: Enum.join(scopes, " ")` when
  the app's scopes is a non-empty list; the parameter is omitted for `nil`
  or `[]` (byte-compatible with old saved credentials — current behavior).
- CHANGELOG bug-fix entry referencing #100.

## Testing

- **Integration (the #100 regression test):** new test doing the README
  flow — `Hunter.create_app/5` → `Hunter.log_in/4` → `create_status` →
  `destroy_status` — which fails with the exact #100 error before the fix.
  Requires a known password: `scripts/ci/setup_mastodon.sh` gains a
  `tootctl accounts modify kadaba --reset-password` step and exports
  `HUNTER_PASSWORD2` (env file + `$GITHUB_ENV`). The test skips nothing:
  password comes from the same env contract as the tokens.
- **Unit:** application persistence tests extended for the scopes round-trip
  (create → save → load); a Mox test pinning that `log_in` receives the app
  with scopes intact; rename covered by the entire existing suite compiling
  and passing (`--warnings-as-errors` catches stragglers).
- Full gate per commit: compile --warnings-as-errors, test, format
  --check-formatted, credo --strict; dialyzer once at the end (struct/type
  changes).

## Out of scope

- `log_in_oauth` redirect_uri verification/fix — new issue to file.
- Any other 0.6.0 items (#107 follow-ups, #110 domain-block auth, #103
  Finch).
