# Query Parameters (#74) and API-Drift Cleanup (#106) Design

**Date:** 2026-07-07
**Status:** Approved
**Related:** [issue #74](https://github.com/milmazz/hunter/issues/74),
[issue #106](https://github.com/milmazz/hunter/issues/106)

## Goal

Make GET/DELETE request options travel as query-string parameters instead of
JSON request bodies (#74), then remove or correct the API surface that modern
Mastodon no longer supports (#106). Ships as two stacked PRs; the breaking
changes land in the already-open 0.6.0 window.

## Background

- `Hunter.Api.Request.request/5` JSON-encodes `data` into the request body
  for every verb. Mastodon (Rails) parses JSON bodies even on GET/DELETE, so
  the library *appears* to work — but proxies and CDNs routinely drop bodies
  on those verbs, and the behavior contradicts the documented API. Issue #74
  reports pagination/filtering (`max_id`, `since_id`, `limit`, `local`)
  silently broken across ~14 GET endpoints.
- `relationships/2` hand-builds its own query string
  (`"/api/v1/accounts/relationships?#{ids_array}"`) — evidence the general
  mechanism is missing.
- Issue #106 as filed is partially stale: `search/3` already targets
  `/api/v2/search`. The real remaining drift: `q` currently travels in a GET
  body (the #74 bug), `Result.hashtags` decodes v1-style strings while v2
  returns objects, `follow_by_uri` targets `POST /api/v1/follows` (removed in
  Mastodon 4.0), and `reports/1` targets `GET /api/v1/reports` (removed).
  Correct the issue with a comment when PR B closes it.

## Decisions (user-approved 2026-07-07)

1. `Result.hashtags` decodes to `[%Hunter.Tag{}]` — v2-faithful, consistent
   with the rest of the library; breaking, lands in 0.6.0.
2. `follow_by_uri` is **removed** (not reimplemented via resolve).
3. `reports/1` (GET) is removed; `report/4` (POST) stays.
4. The query-param fix covers **GET and DELETE**.
5. Mechanism: request-layer routing (approach A below), not per-call-site URL
   building.

## PR A: query parameters (#74)

Branch `query-params` off `main`.

### Mechanism

New pure function in `Hunter.Api.Request`:

```elixir
split_payload(method, data) :: {body, params}
```

- `:get` / `:delete` → `{"", params}` where `params` is a list of
  `{key, value}` tuples derived from `data` (keyword list or map).
- every other verb → `{process_request_body(data), []}` — byte-identical to
  today's body behavior.
- List values encode Rails-style repeated keys: `%{id: [1, 2]}` →
  `[{"id[]", 1}, {"id[]", 2}]`.
- Empty data → `{"", []}`; HTTPoison must not append a bare `?`.

`request/5` passes `params` via HTTPoison's `params:` request option (merged
into the caller-supplied `Config.http_options()` without clobbering other
options). Public signatures of `request/5` and `request!/5` are unchanged.

### Call-site cleanup

`HTTPClient.relationships/2` stops hand-building its query string: endpoint
becomes `"/api/v1/accounts/relationships"` and the ids travel as
`%{id: ids}` through `split_payload`'s array encoding.

No other call sites change — that is the point of the mechanism.

### Tests

- Unit (`test/hunter/api/request_test.exs`): `split_payload/2` routing table
  (GET with options, DELETE with options, POST untouched, array encoding,
  empty data), and that `params` reach the HTTPoison options.
- Integration (`test/integration/mastodon_test.exs`): new assertions that
  prove params take effect server-side — `limit: 1` returns at most one
  result, `max_id` pagination excludes the anchor status. These fail against
  the current body-quirk behavior only if Rails ignores GET bodies — they
  exist to pin the *correct* transport, not to detect the old one, so they
  must pass both locally and in CI after the fix.
- Existing integration tests (`search_account`, `relationships` via the
  follow test) re-verify the migrated paths.

## PR B: API-drift cleanup (#106)

Branch `api-drift` off `query-params` (stacked: its integration test needs
`q` as a real query param).

### Changes

1. **v2 search result shape**: `Transformer.transform(body, :result)` decodes
   `hashtags: [%Hunter.Tag{}]`; `test/fixtures/result.json` corrected to the
   v2 object shape (`[{"name": "elixir", "url": …}]`); transformer test
   updated to assert Tag structs. `Hunter.Result` typespec/docs updated.
2. **Remove `follow_by_uri`**: from `Hunter`, `Hunter.Account`, the
   `Hunter.Api` behaviour callback, `Hunter.Api.HTTPClient`, and its Mox test.
3. **Remove `reports/1`**: from `Hunter`, `Hunter.Report`, the behaviour,
   `HTTPClient`, its Mox test, and the `:reports` transform clause plus its
   transformer test (`report/4` POST and the `:report` clause stay).
4. **CHANGELOG**: three breaking-change entries under Unreleased (0.6.0).
5. **Issue hygiene**: comment on #106 correcting the stale v1-search claim;
   PR closes #106.

### Tests

- Transformer test asserts `%Hunter.Tag{name: "elixir"}` in result hashtags.
- New integration test: post a `#hunterci` status, `Result.search` for it,
  assert the status appears and hashtags decode as Tag structs.
- Compile with `--warnings-as-errors` guarantees no dangling references to
  the removed functions.

## Out of scope

- Finch migration (issue #103) — explicitly deferred by the user.
- `bearer_token` → `access_token` rename (issue #101) — separate 0.6.0 item.
- Test-suite follow-ups (issue #107).
- Any change to POST/PATCH body encoding.

## Sequencing note

Both PRs are stacked; after PR A squash-merges, PR B needs the same
merge-main sync applied to `unit-test-suite`/`integration-tests` last time
(or merge PR A with a merge commit to avoid it).
