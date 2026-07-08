# CI Workflow and Test Suite Design

**Date:** 2026-07-06
**Status:** Approved
**Related:** [issue #13](https://github.com/milmazz/hunter/issues/13)

## Goal

Establish a modern GitHub Actions CI process for hunter and build a robust test
suite: deeper unit tests plus integration tests that run against a real
Mastodon server, both locally and in CI.

## Background

- The existing workflow (`.github/workflows/elixir.yml`) targets the `master`
  branch, but the repository's default branch is `main`, so CI never runs. It
  also pins Elixir 1.14/OTP 25 and uses deprecated action versions.
- `.tool-versions` was recently bumped to Erlang 28 / Elixir 1.19-otp-28, and
  deps were bumped (`httpoison ~> 3.0`, `poison ~> 6.0`). These changes are
  uncommitted and this work builds on them.
- Tests exist for only 6 of ~20 modules. They are Mox-based delegation tests
  that assert the mock returns what it was told to return. The HTTP layer
  (`Hunter.Api.HTTPClient`, `Hunter.Api.Request`), the JSON-to-struct
  transformation, and error handling are untested.
- The codebase already has the right test seam: the `Hunter.Api` behaviour
  with a Mox mock (`Hunter.ApiMock`) configured in `test/test_helper.exs`.

## Part 1: CI workflow

Replace `.github/workflows/elixir.yml` with `.github/workflows/ci.yml`,
triggered on pushes and pull requests to `main`. Four jobs:

### test (matrix)

- Matrix pairs: Elixir 1.15 / OTP 25 (floor) and Elixir 1.19 / OTP 28
  (matching `.tool-versions`).
- `erlef/setup-beam@v1` for toolchain, `actions/checkout@v4`,
  `actions/cache@v4` for `deps/` and `_build/` keyed on
  `os + otp + elixir + hashFiles('mix.lock')`.
- Steps: `mix deps.get`, `mix deps.unlock --check-unused`,
  `mix compile --warnings-as-errors`, `mix test`.
- Consequence: bump `elixir: "~> 1.8"` to `elixir: "~> 1.15"` in `mix.exs`.
  The 1.8 claim is untestable and almost certainly broken by the dep bumps.
  If the floor pair fails against the updated deps in CI, raise the floor to
  the oldest pair that passes and note it in the changelog.

### lint

- Latest pair only: `mix format --check-formatted`, `mix credo --strict`.

### dialyzer

- Latest pair only. Cache the PLT (`actions/cache` keyed on
  `os + otp + elixir + hashFiles('mix.lock')`) so runs are fast after the
  first. Fix stale `:race_conditions`-era flags in the `mix.exs` dialyzer
  config if current dialyxir rejects them.

### integration

- Boots a real Mastodon server via `docker-compose.ci.yml` (postgres, redis,
  mastodon web, streaming, sidekiq) with a **pinned** Mastodon image version,
  bumped deliberately.
- A setup script (`scripts/ci/setup_mastodon.sh`) waits for health, creates a
  confirmed/approved user via `tootctl accounts create`, and provisions an
  OAuth application + access token with full scopes via `rails runner`
  (Doorkeeper), emitting `HUNTER_BASE_URL` and `HUNTER_TOKEN`.
- Runs `mix test --only integration` against that server.

## Part 2: Unit test suite

Three layers, ordered by value:

### Entity parsing tests (biggest gap)

- Real Mastodon API JSON fixtures under `test/fixtures/` for each entity:
  Status, Account, Card, Attachment, Relationship, Notification, Context,
  Instance, Report, Result, Emoji, Tag, Mention.
- Assert that decoding (the `transform/2` path in `Hunter.Api.HTTPClient`,
  i.e. `Poison.decode!(body, as: %Entity{})`) produces correct nested structs
  (e.g. a Status containing an Account, Attachments, Tags).
- These test actual behavior rather than mock echo.

### Mox delegation tests for the full API surface

- Extend the existing pattern from 6 modules to all public API functions:
  Status, Relationship, Report, Result, Context, Attachment, and the
  timeline/favourites/notifications/search functions on `Hunter` itself.
- Include error paths: expectations that raise `Hunter.Error` and assertions
  on the error struct.

### Pure-function tests for the HTTP plumbing

- `Hunter.Api.Request`: request body building (empty, map, multipart,
  binary), header merging, and status-code handling (2xx ok, non-2xx error,
  transport error) for the parts testable without a network.
- `Hunter.Client.new/1` and `Hunter.Config` resolution (env var and
  application-env fallbacks).

## Part 3: Integration suite

- Lives in `test/integration/`, tagged `@moduletag :integration`.
- Excluded by default in `test_helper.exs` (`ExUnit.configure(exclude:
  [:integration])`) so `mix test` stays fast and offline.
- Activated when `HUNTER_BASE_URL` and `HUNTER_TOKEN` are set — the same
  mechanism works locally against any test instance and in the CI job.
- End-to-end flow against the real server: verify credentials → post status →
  favourite/reblog → search → follow/notifications → upload media → delete
  status → instance metadata. Tests clean up what they create where the API
  allows it.

## Sequencing

1. Commit the pending dep bumps (`mix.exs`, `mix.lock`, `.tool-versions`) as
   the first commit of the branch.
2. CI workflow for unit/lint/dialyzer jobs (immediate value, no test changes
   needed).
3. Unit test layers (entity parsing → delegation coverage → HTTP plumbing).
4. Integration suite + Mastodon-in-Docker CI job.

## Out of scope

- Replacing Poison/HTTPoison with newer stacks (Req/Jason) — separate effort.
- Coverage reporting (declined during design).
- Streaming API (`Hunter.EventStream`) integration tests — websocket/SSE
  testing is a follow-up.

## Errata (post-implementation)

Recorded after the stack merged; the sections above are the point-in-time
design and are intentionally left as written.

- The matrix floor shipped as **Elixir 1.15 / OTP 26**, not OTP 25: the
  updated dependency lock (`quic 1.7.0`, via hackney) does not compile on
  OTP 25. Exercised the spec's own escape hatch; recorded in CHANGELOG and
  PR #102.
- The integration env contract grew beyond `HUNTER_BASE_URL`/`HUNTER_TOKEN`:
  the suite also requires `HUNTER_TOKEN2` (second account, follow/notification
  tests), and later `HUNTER_PASSWORD2` (password-grant auth-flow test, #100)
  and `HUNTER_OAUTH_CLIENT_ID`/`HUNTER_OAUTH_CLIENT_SECRET`/`HUNTER_OAUTH_CODE`
  (OAuth flow test, #112). `scripts/ci/setup_mastodon.sh` provisions all of
  them; see CONTRIBUTING.md for the current list.
