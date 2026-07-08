# Modern-Mastodon Endpoint Fixes Design (#118)

**Date:** 2026-07-08
**Status:** Approved
**Related:** [issue #118](https://github.com/milmazz/hunter/issues/118), part
of the Mastodon 4.6 API parity effort (#118–#128)

## Goal

Fix the endpoints that are broken or deprecated on modern Mastodon servers
before the 0.6.0 release, so the release doesn't ship API calls that can only
fail. One branch (`fix-api-drift-4x` off `main`), one PR. The password-grant
deprecation stays with #126.

## Decisions (user-approved 2026-07-08)

1. **Media v2 returns as-is**: no library-side polling; `url` may be `nil`
   while the server processes asynchronously, documented on `upload_media`.
2. **Instance v2 reshape is top-level only**: nested objects decode as plain
   maps; full nested-struct modeling stays with #119.
3. PR is left unmerged for the user's manual review (standing instruction).

## Part 1: preview cards (breaking)

`GET /api/v1/statuses/:id/card` was removed in Mastodon 3.0; the card is
embedded in the Status entity.

- `Hunter.Status` gains a `card` field (`Hunter.Card.t() | nil`): struct,
  `@type`, fields doc.
- `Transformer.status_nested_struct/0` decodes `card: %Hunter.Card{}`.
- `test/fixtures/status.json` gains a `card` object; transformer test asserts
  the nested `%Hunter.Card{}`.
- **Removed** everywhere (function + doc + spec/callback): `Hunter.card_by_status/2`
  delegate, `Hunter.Card.card_by_status/2`, the `Hunter.Api` callback, the
  HTTPClient implementation, the Mox test in `test/hunter/card_test.exs`, and
  the now-orphaned `:card` transform clause plus its transformer test. The
  `Hunter.Card` struct itself stays (embedded entity).

## Part 2: follow requests (breaking return type)

The implemented `POST /api/v1/follow_requests/#{action}` with an `id` body
never matched the documented API.

- Paths become `POST /api/v1/follow_requests/:account_id/authorize` and
  `.../reject`; empty payload; decode `:relationship` (the endpoint returns a
  `Relationship` since 3.0).
- `follow_request_action` callback and the `accept_follow_request/2` /
  `reject_follow_request/2` wrappers change spec from `boolean` to
  `Hunter.Relationship.t()`.
- Mox tests updated to the new return shape.
- **Integration test** (the old path was broken and the suite never noticed —
  this coverage is the point): `conn2` locks its own account via
  `Account.update_credentials(conn2, %{locked: true})` (with an `on_exit`
  unlock net); `conn` follows `id2` and asserts `requested: true`; `conn2`
  sees the request in `Account.follow_requests/1` (asserting the requester's
  account appears) and calls `accept_follow_request(conn2, id1)`, asserting
  the returned `%Hunter.Relationship{followed_by: true}`; cleanup unfollows
  and unlocks via `on_exit` nets so the pre-existing follow test is unaffected
  regardless of intra-module test order.

## Part 3: notification dismiss (path fix)

- `clear_notification/2` path becomes
  `POST /api/v1/notifications/#{id}/dismiss` (the implemented
  `/notifications/dismiss/#{id}` matches no server version).
- The existing cross-account notification integration test extends: capture
  the mention notification's id, dismiss it, assert it no longer appears in
  `Notification.notifications/1`.

## Part 4: media v2 (deprecated migration)

- `upload_media/3` posts to `POST /api/v2/media` (multipart handling
  unchanged).
- Response returned as-is; the function docs (`Hunter.Attachment.upload_media/3`
  and the `Hunter` delegate doc) document that `url` may be `nil` until the
  server finishes processing (v2 answers 202 for large files) and that the
  attachment `id` is immediately usable with `create_status` once processing
  completes.
- Existing live media test covers the endpoint swap (it already retries
  `create_status` via `eventually`).

## Part 5: instance v2 (breaking reshape)

- `instance_info/1` targets `GET /api/v2/instance`.
- `Hunter.Instance` reshapes to the v2 top-level fields:
  `defstruct [:domain, :title, :version, :source_url, :description, :usage,
  :thumbnail, :languages, :configuration, :registrations, :contact, :rules]`
  — nested objects as plain maps; `@type` and fields doc updated.
- `test/fixtures/instance.json` rewritten to the v2 shape; transformer test
  asserts `domain`/`version` and a nested plain-map field.
- Live instance test asserts `domain`/`version` instead of `uri`.

## CHANGELOG

- Breaking: card_by_status removal (+ `Status.card` addition), follow-request
  return type + endpoint fix, Instance v2 reshape.
- Bug fixes: notification dismiss path, follow-request path (called out as
  previously non-functional), media v2 migration note.
- All referencing [#118].

## Testing

Full unit gate per commit (compile --warnings-as-errors, test, format, credo
--strict); dialyzer once before the PR (struct/callback changes); full live
integration run (13 tests expected: 12 existing + the follow-request test,
with the dismiss step folded into an existing test) via
`./scripts/ci/setup_mastodon.sh` + `mix test --only integration`.

## Out of scope

- Password-grant OAuth deprecation (#126), entity modernization beyond
  Instance top-level (#119), everything else in #120–#128.
- Merging the PR (user reviews manually).
