# CI Workflow and Test Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modern GitHub Actions CI plus a robust unit test suite and an integration suite that runs against a real Mastodon server, delivered as three stacked PRs.

**Architecture:** PR1 (`ci-workflow`, off `main`) replaces the dead workflow with a matrix test/lint/dialyzer pipeline. PR2 (`unit-test-suite`, off `ci-workflow`) extracts the JSON→struct transformation into a testable module, refactors `Hunter.Api.Request` for pure-function testing, and extends Mox delegation coverage to the full API surface. PR3 (`integration-tests`, off `unit-test-suite`) adds a tagged integration suite driven by `HUNTER_BASE_URL`/`HUNTER_TOKEN`, a docker-compose Mastodon stack (nginx TLS in front, because Mastodon production mode forces SSL), and a CI job that boots it.

**Tech Stack:** Elixir/ExUnit, Mox, Poison 6, HTTPoison 3, GitHub Actions (`erlef/setup-beam`), Docker Compose, Mastodon `v4.3.8` (pinned), nginx TLS sidecar.

**Spec:** `docs/superpowers/specs/2026-07-06-ci-and-test-suite-design.md`

## Global Constraints

- Elixir requirement in `mix.exs` becomes `~> 1.15`; CI matrix floor is Elixir 1.15 / OTP 25, latest is Elixir 1.19 / OTP 28. If the floor pair fails in CI due to dep requirements, raise the floor to the oldest passing pair and record it in CHANGELOG.md.
- Keep Poison/HTTPoison — no HTTP/JSON stack migration.
- All code must pass `mix format --check-formatted`, `mix credo --strict`, and compile with `--warnings-as-errors`.
- Every commit message follows the repo's plain style (e.g. "add entity parsing tests") and ends with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- `mix test` (no env vars) must stay fast and offline — integration tests are excluded by default.
- Mastodon docker image is pinned to `ghcr.io/mastodon/mastodon:v4.3.8`; version bumps are deliberate. (At execution time, if that tag does not exist, use the newest existing `v4.3.x` tag.)
- Stacked branches: `ci-workflow` → `unit-test-suite` → `integration-tests`. PR bases follow the stack.
- PR bodies end with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

---

# PR1: CI workflow (branch `ci-workflow`, base `main`)

### Task 1: Branch, baseline, and commit the pending dep bumps

The working tree already contains uncommitted bumps (`.tool-versions` → erlang 28 / elixir 1.19-otp-28; `mix.exs` → httpoison ~> 3.0, poison ~> 6.0; `mix.lock`). Verify they are green, then make them the branch's first commit.

**Files:**
- Modify (already modified, commit as-is): `.tool-versions`, `mix.exs`, `mix.lock`

- [ ] **Step 1: Create the branch**

```bash
git checkout -b ci-workflow
```

- [ ] **Step 2: Verify the baseline is green**

Run: `mix deps.get && mix compile --warnings-as-errors && mix test`
Expected: 0 failures. If compile warnings or test failures appear, STOP and fix them (systematic-debugging) before anything else — they are pre-existing breakage from the dep bumps and belong in this commit.

- [ ] **Step 3: Commit**

```bash
git add .tool-versions mix.exs mix.lock
git commit -m "update httpoison/poison and toolchain to erlang 28 / elixir 1.19"
```

### Task 2: mix.exs project hygiene for CI

**Files:**
- Modify: `mix.exs` (project/0: `elixir` requirement and `dialyzer` config)
- Modify: `.gitignore` (add PLT dir)

**Interfaces:**
- Produces: dialyzer PLT at `priv/plts/project.plt` — Task 3's CI cache and dialyzer job depend on this exact path.

- [ ] **Step 1: Update `mix.exs`**

In `project/0`, change `elixir: "~> 1.8"` to:

```elixir
      elixir: "~> 1.15",
```

Replace the `dialyzer:` keyword with (the `:race_conditions` flag was removed in modern OTP and errors out):

```elixir
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
        plt_file: {:no_warn, "priv/plts/project.plt"},
        flags: [:error_handling, :underspecs]
      ]
```

- [ ] **Step 2: Add PLT dir to `.gitignore`**

Append:

```
/priv/plts/
```

- [ ] **Step 3: Verify compile, format, credo, and dialyzer**

Run: `mkdir -p priv/plts && mix compile --warnings-as-errors && mix format --check-formatted && mix credo --strict && mix dialyzer`
Expected: compile/format/credo clean. First dialyzer run builds the PLT (several minutes). If dialyzer reports pre-existing warnings in `lib/`, do NOT fix them here — record the count; Task 3 makes the dialyzer job non-blocking only if it cannot be made green with `@dialyzer` ignores or a `.dialyzer_ignore.exs` file. Prefer an ignore file:

```elixir
# .dialyzer_ignore.exs — pre-existing findings, tracked to be fixed separately
[]
```

and `ignore_warnings: ".dialyzer_ignore.exs"` added to the `dialyzer:` config with the actual entries dialyzer prints.

- [ ] **Step 4: Run tests and commit**

Run: `mix test`
Expected: PASS

```bash
git add mix.exs .gitignore .dialyzer_ignore.exs 2>/dev/null || git add mix.exs .gitignore
git commit -m "require elixir 1.15+, fix dialyzer config for modern OTP"
```

### Task 3: Replace the workflow and open PR1

**Files:**
- Delete: `.github/workflows/elixir.yml`
- Create: `.github/workflows/ci.yml`

**Interfaces:**
- Produces: workflow name `CI` with jobs `test`, `lint`, `dialyzer`. PR3's Task 12 appends an `integration` job to this same file.

- [ ] **Step 1: Delete the old workflow and write `.github/workflows/ci.yml`**

```bash
git rm .github/workflows/elixir.yml
```

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  test:
    name: Test (Elixir ${{ matrix.elixir }} / OTP ${{ matrix.otp }})
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        include:
          - elixir: "1.15"
            otp: "25"
          - elixir: "1.19"
            otp: "28"
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: ${{ matrix.elixir }}
          otp-version: ${{ matrix.otp }}
      - uses: actions/cache@v4
        with:
          path: |
            deps
            _build
          key: mix-${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-${{ hashFiles('mix.lock') }}
          restore-keys: |
            mix-${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-
      - run: mix deps.get
      - run: mix deps.unlock --check-unused
      - run: mix compile --warnings-as-errors
      - run: mix test

  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          version-file: .tool-versions
          version-type: strict
      - uses: actions/cache@v4
        with:
          path: |
            deps
            _build
          key: mix-lint-${{ runner.os }}-${{ hashFiles('.tool-versions', 'mix.lock') }}
          restore-keys: |
            mix-lint-${{ runner.os }}-
      - run: mix deps.get
      - run: mix format --check-formatted
      - run: mix credo --strict

  dialyzer:
    name: Dialyzer
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          version-file: .tool-versions
          version-type: strict
      - uses: actions/cache@v4
        with:
          path: |
            deps
            _build
            priv/plts
          key: mix-plt-${{ runner.os }}-${{ hashFiles('.tool-versions', 'mix.lock') }}
          restore-keys: |
            mix-plt-${{ runner.os }}-
      - run: mix deps.get
      - run: mkdir -p priv/plts
      - run: mix dialyzer
```

Note: `.tool-versions` says `erlang 28` / `elixir 1.19-otp-28`. `version-type: strict` requires resolvable versions — if setup-beam rejects the loose `28`, pin `.tool-versions` to full versions (e.g. `erlang 28.0.1`, `elixir 1.19.0-otp-28`) in this task and keep `strict`.

- [ ] **Step 2: Commit, push, and open PR1**

```bash
git add .github/workflows/ci.yml
git commit -m "replace stale master-only workflow with matrix CI (test/lint/dialyzer)"
git push -u origin ci-workflow
gh pr create --base main --title "Modernize CI: matrix tests, lint, dialyzer" --body "$(cat <<'EOF'
Replaces the stale workflow (targeted the old `master` branch, so CI never ran) with a matrix pipeline.

- Test matrix: Elixir 1.15/OTP 25 (new floor, `mix.exs` now requires `~> 1.15`) and Elixir 1.19/OTP 28
- `mix deps.unlock --check-unused` re-enabled
- Lint job: `mix format --check-formatted` + `mix credo --strict`
- Dialyzer job with PLT caching; removed the retired `:race_conditions` flag
- Includes the pending httpoison 3.0 / poison 6.0 / toolchain bumps

Part 1 of 3 stacked PRs implementing docs/superpowers/specs/2026-07-06-ci-and-test-suite-design.md (issue #13).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 3: Watch CI to green**

Run: `gh pr checks --watch`
Expected: all jobs pass. If the 1.15/OTP 25 job fails on dep requirements, raise the floor per Global Constraints (edit matrix + `mix.exs` + note in CHANGELOG.md, commit "raise supported elixir floor to <version>"), and re-push.

---

# PR2: Unit test suite (branch `unit-test-suite`, base `ci-workflow`)

```bash
git checkout ci-workflow && git checkout -b unit-test-suite
```

### Task 4: Entity fixtures + failing transformer tests

**Files:**
- Create: `test/fixtures/account.json`, `test/fixtures/status.json`, `test/fixtures/notification.json`, `test/fixtures/context.json`, `test/fixtures/instance.json`, `test/fixtures/card.json`, `test/fixtures/relationship.json`, `test/fixtures/report.json`, `test/fixtures/result.json`, `test/fixtures/attachment.json`
- Create: `test/hunter/api/transformer_test.exs`

**Interfaces:**
- Consumes: nothing (tests written first; module arrives in Task 5).
- Produces: `Hunter.Api.Transformer.transform(body :: String.t(), to :: atom) :: struct | [struct] | map` — the contract Task 5 implements. Fixtures are shared with nothing else (integration uses a live server).

- [ ] **Step 1: Write the fixtures**

`test/fixtures/account.json`:

```json
{
  "id": "23634",
  "username": "milmazz",
  "acct": "milmazz",
  "display_name": "Milton Mazzarri",
  "locked": false,
  "created_at": "2017-04-06T13:15:24.420Z",
  "followers_count": 118,
  "following_count": 178,
  "statuses_count": 33,
  "note": "<p>hunter author</p>",
  "url": "https://mastodon.example/@milmazz",
  "avatar": "https://mastodon.example/avatars/original/missing.png",
  "avatar_static": "https://mastodon.example/avatars/original/missing.png",
  "header": "https://mastodon.example/headers/original/missing.png",
  "header_static": "https://mastodon.example/headers/original/missing.png"
}
```

`test/fixtures/attachment.json`:

```json
{
  "id": "22345792",
  "type": "image",
  "url": "https://mastodon.example/media/image.png",
  "preview_url": "https://mastodon.example/media/image_small.png",
  "remote_url": null,
  "text_url": "https://mastodon.example/media/xYzabc",
  "meta": {
    "original": { "width": 640, "height": 480 }
  },
  "description": "test media"
}
```

`test/fixtures/status.json` (exercises every nested entity of `status_nested_struct/0`):

```json
{
  "id": "103270115826048975",
  "uri": "https://mastodon.example/users/milmazz/statuses/103270115826048975",
  "url": "https://mastodon.example/@milmazz/103270115826048975",
  "in_reply_to_id": null,
  "in_reply_to_account_id": null,
  "reblog": null,
  "content": "<p>Testing <a href=\"https://mastodon.example/tags/elixir\">#elixir</a> with @kadaba</p>",
  "created_at": "2019-12-08T03:48:33.901Z",
  "reblogs_count": 6,
  "favourites_count": 11,
  "reblogged": false,
  "favourited": false,
  "muted": false,
  "sensitive": false,
  "spoiler_text": "",
  "visibility": "public",
  "language": "en",
  "account": {
    "id": "23634",
    "username": "milmazz",
    "acct": "milmazz",
    "display_name": "Milton Mazzarri",
    "url": "https://mastodon.example/@milmazz"
  },
  "media_attachments": [
    {
      "id": "22345792",
      "type": "image",
      "url": "https://mastodon.example/media/image.png",
      "preview_url": "https://mastodon.example/media/image_small.png"
    }
  ],
  "mentions": [
    {
      "id": "8039",
      "username": "kadaba",
      "acct": "kadaba",
      "url": "https://mastodon.example/@kadaba"
    }
  ],
  "tags": [
    {
      "name": "elixir",
      "url": "https://mastodon.example/tags/elixir"
    }
  ],
  "application": {
    "name": "hunter",
    "website": null
  }
}
```

`test/fixtures/notification.json`:

```json
{
  "id": "34975861",
  "type": "mention",
  "created_at": "2019-11-23T07:49:02.064Z",
  "account": {
    "id": "8039",
    "username": "kadaba",
    "acct": "kadaba"
  },
  "status": {
    "id": "103270115826048975",
    "content": "<p>hello @milmazz</p>",
    "visibility": "public"
  }
}
```

`test/fixtures/context.json`:

```json
{
  "ancestors": [
    { "id": "103270115826048970", "content": "<p>parent</p>", "visibility": "public" }
  ],
  "descendants": [
    { "id": "103270115826048999", "content": "<p>reply</p>", "visibility": "public" }
  ]
}
```

`test/fixtures/instance.json`:

```json
{
  "uri": "mastodon.example",
  "title": "Mastodon Example",
  "description": "A test instance",
  "email": "admin@mastodon.example",
  "version": "4.3.8",
  "urls": {
    "streaming_api": "wss://mastodon.example"
  }
}
```

`test/fixtures/card.json`:

```json
{
  "url": "https://elixir-lang.org/",
  "title": "The Elixir programming language",
  "description": "Elixir is a dynamic, functional language.",
  "type": "link",
  "author_name": "",
  "author_url": "",
  "provider_name": "elixir-lang.org",
  "provider_url": "https://elixir-lang.org",
  "image": "https://mastodon.example/preview_cards/image.png"
}
```

`test/fixtures/relationship.json`:

```json
{
  "id": "8039",
  "following": true,
  "followed_by": false,
  "blocking": false,
  "muting": false,
  "requested": false,
  "domain_blocking": false
}
```

`test/fixtures/report.json`:

```json
{
  "id": "48914",
  "action_taken": false
}
```

`test/fixtures/result.json`:

```json
{
  "accounts": [
    { "id": "23634", "username": "milmazz", "acct": "milmazz" }
  ],
  "statuses": [
    { "id": "103270115826048975", "content": "<p>Testing #elixir</p>", "visibility": "public" }
  ],
  "hashtags": ["elixir"]
}
```

- [ ] **Step 2: Write the failing test file**

`test/hunter/api/transformer_test.exs`:

```elixir
defmodule Hunter.Api.TransformerTest do
  use ExUnit.Case, async: true

  alias Hunter.Api.Transformer

  test "decodes an account" do
    account = transform("account", :account)

    assert %Hunter.Account{} = account
    assert account.username == "milmazz"
    assert account.acct == "milmazz"
    assert account.display_name == "Milton Mazzarri"
    assert account.followers_count == 118
    assert account.url == "https://mastodon.example/@milmazz"
  end

  test "decodes a list of accounts" do
    assert [%Hunter.Account{username: "milmazz"}] =
             transform_list("account", :accounts)
  end

  test "decodes a status with nested entities" do
    status = transform("status", :status)

    assert %Hunter.Status{visibility: "public", language: "en"} = status
    assert status.reblogs_count == 6
    assert %Hunter.Account{username: "milmazz"} = status.account
    assert [%Hunter.Attachment{id: "22345792", type: "image"}] = status.media_attachments
    assert [%Hunter.Mention{username: "kadaba", acct: "kadaba"}] = status.mentions
    assert [%Hunter.Tag{name: "elixir"}] = status.tags
    assert status.reblog == nil
  end

  test "decodes a list of statuses" do
    assert [%Hunter.Status{account: %Hunter.Account{username: "milmazz"}}] =
             transform_list("status", :statuses)
  end

  test "decodes a notification with nested account and status" do
    notification = transform("notification", :notification)

    assert %Hunter.Notification{type: "mention"} = notification
    assert %Hunter.Account{username: "kadaba"} = notification.account
    assert %Hunter.Status{content: "<p>hello @milmazz</p>"} = notification.status
  end

  test "decodes a list of notifications" do
    assert [%Hunter.Notification{type: "mention"}] =
             transform_list("notification", :notifications)
  end

  test "decodes a context with status ancestors and descendants" do
    context = transform("context", :context)

    assert %Hunter.Context{} = context
    assert [%Hunter.Status{content: "<p>parent</p>"}] = context.ancestors
    assert [%Hunter.Status{content: "<p>reply</p>"}] = context.descendants
  end

  test "decodes an instance" do
    instance = transform("instance", :instance)

    assert %Hunter.Instance{uri: "mastodon.example", version: "4.3.8"} = instance
    assert instance.urls["streaming_api"] == "wss://mastodon.example"
  end

  test "decodes a card" do
    assert %Hunter.Card{title: "The Elixir programming language", type: "link"} =
             transform("card", :card)
  end

  test "decodes a relationship" do
    assert %Hunter.Relationship{following: true, blocking: false} =
             transform("relationship", :relationship)
  end

  test "decodes a list of relationships" do
    assert [%Hunter.Relationship{following: true}] =
             transform_list("relationship", :relationships)
  end

  test "decodes a report" do
    assert %Hunter.Report{id: "48914", action_taken: false} = transform("report", :report)
  end

  test "decodes a list of reports" do
    assert [%Hunter.Report{id: "48914"}] = transform_list("report", :reports)
  end

  test "decodes a search result with nested accounts and statuses" do
    result = transform("result", :result)

    assert %Hunter.Result{hashtags: ["elixir"]} = result
    assert [%Hunter.Account{username: "milmazz"}] = result.accounts
    assert [%Hunter.Status{visibility: "public"}] = result.statuses
  end

  test "decodes an attachment" do
    attachment = transform("attachment", :attachment)

    assert %Hunter.Attachment{type: "image", description: "test media"} = attachment
    assert attachment.meta["original"]["width"] == 640
  end

  test "falls back to a plain map for unknown entities" do
    assert %{"id" => "48914"} = transform("report", :unknown)
  end

  defp transform(fixture_name, to) do
    fixture_name
    |> fixture()
    |> Transformer.transform(to)
  end

  defp transform_list(fixture_name, to) do
    Transformer.transform("[" <> fixture(fixture_name) <> "]", to)
  end

  defp fixture(name) do
    [__DIR__, "..", "..", "fixtures", name <> ".json"]
    |> Path.join()
    |> Path.expand()
    |> File.read!()
  end
end
```

- [ ] **Step 3: Run to verify it fails**

Run: `mix test test/hunter/api/transformer_test.exs`
Expected: FAIL — `Hunter.Api.Transformer` is undefined.

- [ ] **Step 4: Commit the red state**

```bash
git add test/fixtures test/hunter/api/transformer_test.exs
git commit -m "add entity fixtures and failing transformer tests"
```

### Task 5: Extract `Hunter.Api.Transformer`

**Files:**
- Create: `lib/hunter/api/transformer.ex`
- Modify: `lib/hunter/api/http_client.ex` (delete the private `transform/2` clauses and `status_nested_struct/0` / `notification_nested_struct/0`; call the new module)

**Interfaces:**
- Consumes: contract from Task 4.
- Produces: `Hunter.Api.Transformer.transform/2`, used by `Hunter.Api.HTTPClient.request!/5`.

- [ ] **Step 1: Create `lib/hunter/api/transformer.ex`**

Move the bodies verbatim from `lib/hunter/api/http_client.ex` (the `defp transform` clauses at roughly lines 391–470 and the two nested-struct helpers):

```elixir
defmodule Hunter.Api.Transformer do
  @moduledoc """
  Decodes Mastodon API JSON payloads into Hunter entity structs.
  """

  def transform(body, :account), do: Poison.decode!(body, as: %Hunter.Account{})

  def transform(body, :accounts), do: Poison.decode!(body, as: [%Hunter.Account{}])

  def transform(body, :application), do: Poison.decode!(body, as: %Hunter.Application{})

  def transform(body, :attachment), do: Poison.decode!(body, as: %Hunter.Attachment{})

  def transform(body, :card), do: Poison.decode!(body, as: %Hunter.Card{})

  def transform(body, :context) do
    Poison.decode!(
      body,
      as: %Hunter.Context{ancestors: [status_nested_struct()], descendants: [status_nested_struct()]}
    )
  end

  def transform(body, :instance), do: Poison.decode!(body, as: %Hunter.Instance{})

  def transform(body, :notification), do: Poison.decode!(body, as: notification_nested_struct())

  def transform(body, :notifications), do: Poison.decode!(body, as: [notification_nested_struct()])

  def transform(body, :status), do: Poison.decode!(body, as: status_nested_struct())

  def transform(body, :statuses), do: Poison.decode!(body, as: [status_nested_struct()])

  def transform(body, :relationship), do: Poison.decode!(body, as: %Hunter.Relationship{})

  def transform(body, :relationships), do: Poison.decode!(body, as: [%Hunter.Relationship{}])

  def transform(body, :report), do: Poison.decode!(body, as: %Hunter.Report{})

  def transform(body, :reports), do: Poison.decode!(body, as: [%Hunter.Report{}])

  def transform(body, :result) do
    Poison.decode!(
      body,
      as: %Hunter.Result{accounts: [%Hunter.Account{}], statuses: [status_nested_struct()]}
    )
  end

  def transform(body, _), do: Poison.decode!(body)

  defp status_nested_struct do
    %Hunter.Status{
      account: %Hunter.Account{},
      reblog: %Hunter.Status{},
      media_attachments: [%Hunter.Attachment{}],
      mentions: [%Hunter.Mention{}],
      tags: [%Hunter.Tag{}],
      application: %Hunter.Application{}
    }
  end

  defp notification_nested_struct do
    %Hunter.Notification{
      account: %Hunter.Account{},
      status: status_nested_struct()
    }
  end
end
```

Note two deliberate behavior improvements vs. the original (they make Task 4's nested-entity assertions pass): `:context` and `:result` now decode nested statuses with `status_nested_struct()` (the original used bare `%Hunter.Status{}`, leaving inner accounts/tags as plain maps), and `:notification`'s status uses `status_nested_struct()` too. `:reblog` stays `%Hunter.Status{}` inside `status_nested_struct/0` exactly as the original — do not recurse.

- [ ] **Step 2: Wire `HTTPClient` to it**

In `lib/hunter/api/http_client.ex`: add `alias Hunter.Api.Transformer` to the existing alias line, replace the `transform(body, to)` call inside `request!/5` with `Transformer.transform(body, to)`, and delete all `defp transform` clauses plus `status_nested_struct/0` and `notification_nested_struct/0`.

- [ ] **Step 3: Run the whole suite**

Run: `mix compile --warnings-as-errors && mix test`
Expected: PASS, including all transformer tests.

- [ ] **Step 4: Format, lint, commit**

Run: `mix format && mix credo --strict`

```bash
git add lib/hunter/api/transformer.ex lib/hunter/api/http_client.ex
git commit -m "extract JSON-to-struct transformation into Hunter.Api.Transformer"
```

### Task 6: `Hunter.Api.Request` refactor + tests

**Files:**
- Modify: `lib/hunter/api/request.ex`
- Create: `test/hunter/api/request_test.exs`

**Interfaces:**
- Produces: public `Hunter.Api.Request.handle_response/1`, `process_request_body/1`, `process_request_header/1`. `request/5` and `request!/5` keep their exact signatures — `Hunter.Api.HTTPClient` and `Hunter.Client` call them unchanged.

- [ ] **Step 1: Write the failing tests**

`test/hunter/api/request_test.exs`:

```elixir
defmodule Hunter.Api.RequestTest do
  use ExUnit.Case, async: true

  alias Hunter.Api.Request

  describe "process_request_body/1" do
    test "empty payload becomes an empty JSON object" do
      assert Request.process_request_body([]) == "{}"
    end

    test "multipart payloads pass through untouched" do
      payload = {:multipart, [{:file, "/tmp/image.png"}]}
      assert Request.process_request_body(payload) == payload
    end

    test "binary payloads pass through untouched" do
      assert Request.process_request_body(~s({"status":"hi"})) == ~s({"status":"hi"})
    end

    test "maps are JSON-encoded" do
      assert Request.process_request_body(%{status: "hi"}) == ~s({"status":"hi"})
    end
  end

  describe "process_request_header/1" do
    test "sets JSON content-type and accept defaults" do
      headers = Request.process_request_header([])

      assert headers[:"Content-Type"] == "application/json"
      assert headers[:Accept] == "Application/json; Charset=utf-8"
    end

    test "caller headers are preserved and win over defaults" do
      headers =
        Request.process_request_header(
          Authorization: "Bearer 123",
          "Content-Type": "multipart/form-data"
        )

      assert headers[:Authorization] == "Bearer 123"
      assert headers[:"Content-Type"] == "multipart/form-data"
    end
  end

  describe "handle_response/1" do
    test "2xx responses return the body" do
      assert Request.handle_response({:ok, %{status_code: 200, body: "ok"}}) == {:ok, "ok"}
      assert Request.handle_response({:ok, %{status_code: 204, body: ""}}) == {:ok, ""}
    end

    test "non-2xx responses return the body as error" do
      body = ~s({"error":"Record not found"})
      assert Request.handle_response({:ok, %{status_code: 404, body: body}}) == {:error, body}
    end

    test "transport errors return the reason" do
      assert Request.handle_response({:error, %HTTPoison.Error{reason: :econnrefused}}) ==
               {:error, :econnrefused}
    end
  end
end
```

- [ ] **Step 2: Run to verify failure**

Run: `mix test test/hunter/api/request_test.exs`
Expected: FAIL — the three functions are private/undefined.

- [ ] **Step 3: Refactor `lib/hunter/api/request.ex`**

```elixir
defmodule Hunter.Api.Request do
  @moduledoc false

  def request(http_method, url, data \\ [], headers \\ [], options \\ []) do
    body = process_request_body(data)
    headers = process_request_header(headers)

    http_method
    |> HTTPoison.request(url, body, headers, options)
    |> handle_response()
  end

  def request!(http_method, url, data \\ [], headers \\ [], options \\ []) do
    case request(http_method, url, data, headers, options) do
      {:ok, body} -> body
      {:error, reason} -> raise Hunter.Error, reason: reason
    end
  end

  @doc false
  def handle_response({:ok, %{status_code: status, body: body}}) when status in 200..299 do
    {:ok, body}
  end

  def handle_response({:ok, %{body: body}}), do: {:error, body}

  def handle_response({:error, %HTTPoison.Error{reason: reason}}), do: {:error, reason}

  @doc false
  def process_request_body([]), do: "{}"
  def process_request_body({:multipart, _} = data), do: data
  def process_request_body(data) when is_binary(data), do: data
  def process_request_body(data), do: Poison.encode!(data)

  @doc false
  def process_request_header(data) do
    Keyword.merge(
      ["Content-Type": "application/json", Accept: "Application/json; Charset=utf-8"],
      data
    )
  end
end
```

- [ ] **Step 4: Run, format, commit**

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`
Expected: PASS

```bash
git add lib/hunter/api/request.ex test/hunter/api/request_test.exs
git commit -m "expose Request response/body/header handling and cover with tests"
```

### Task 7: `Hunter.Client`, `Hunter.Config`, and `Hunter.Error` tests

**Files:**
- Create: `test/hunter/client_test.exs`, `test/hunter/config_test.exs`, `test/hunter/error_test.exs`

- [ ] **Step 1: Write the tests**

`test/hunter/client_test.exs`:

```elixir
defmodule Hunter.ClientTest do
  use ExUnit.Case, async: true

  alias Hunter.Client

  describe "new/1" do
    test "builds a client with the given options" do
      conn = Client.new(base_url: "https://example.com", bearer_token: "123456")

      assert %Client{base_url: "https://example.com", bearer_token: "123456"} = conn
    end

    test "defaults the base_url from configuration" do
      conn = Client.new(bearer_token: "123456")

      assert conn.base_url == Hunter.Config.api_base_url()
    end
  end

  test "user_agent/0 advertises hunter and its version" do
    assert Client.user_agent() =~ "hunter"
  end
end
```

Before writing assertions for `new/1` defaults, read `lib/hunter/client.ex:26` — `new/1` may not default `base_url`; if it simply takes options, keep only the first test and drop the default test. Adjust `user_agent/0` assertion to the actual format at `lib/hunter/client.ex:34`.

`test/hunter/config_test.exs` (env-var fallbacks; `async: false` because it mutates global state — ExUnit runs sync modules serially after the async ones, so this cannot race the async suite):

```elixir
defmodule Hunter.ConfigTest do
  use ExUnit.Case, async: false

  alias Hunter.Config

  test "home/0 prefers the HUNTER_HOME environment variable" do
    previous = System.get_env("HUNTER_HOME")
    System.put_env("HUNTER_HOME", "/tmp/hunter-home")

    assert Config.home() == "/tmp/hunter-home"

    if previous do
      System.put_env("HUNTER_HOME", previous)
    else
      System.delete_env("HUNTER_HOME")
    end
  end

  test "hunter_api/0 falls back to the HTTP client when unconfigured" do
    Application.delete_env(:hunter, :hunter_api)

    try do
      assert Config.hunter_api() == Hunter.Api.HTTPClient
    after
      Application.put_env(:hunter, :hunter_api, Hunter.ApiMock)
    end
  end
end
```

(`Config.api_base_url/0` and `http_options/0` defaults are already covered by the doctests in `test/hunter_test.exs`.)

`test/hunter/error_test.exs`:

```elixir
defmodule Hunter.ErrorTest do
  use ExUnit.Case, async: true

  test "message renders the reason" do
    error = %Hunter.Error{reason: :econnrefused}

    assert Exception.message(error) == ":econnrefused"
  end

  test "raising with a reason" do
    assert_raise Hunter.Error, ~s("boom"), fn ->
      raise Hunter.Error, reason: "boom"
    end
  end
end
```

- [ ] **Step 2: Run**

Run: `mix test test/hunter/client_test.exs test/hunter/error_test.exs`
Expected: PASS (these test existing code; if an assertion mismatches actual behavior, fix the assertion to the real behavior — do not change lib code in this task).

- [ ] **Step 3: Commit**

```bash
git add test/hunter/client_test.exs test/hunter/config_test.exs test/hunter/error_test.exs
git commit -m "add client, config, and error tests"
```

### Task 8: Complete `Hunter.Status` delegation coverage

**Files:**
- Modify: `test/hunter/status_test.exs` (currently 3 tests: home timeline, public timeline, create status)

**Interfaces:**
- Consumes: `Hunter.ApiMock` (configured in `test/test_helper.exs`), functions at `lib/hunter/status.ex:105-295`.

- [ ] **Step 1: Extend `test/hunter/status_test.exs`**

Keep the existing 3 tests and the existing `@conn`/`setup :verify_on_exit!` head; add:

```elixir
  test "returns a single status" do
    expect(Hunter.ApiMock, :status, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452"}
    end)

    assert %Status{id: "153452"} = Status.status(@conn, 153_452)
  end

  test "destroys a status" do
    expect(Hunter.ApiMock, :destroy_status, fn %Hunter.Client{}, 153_452 -> true end)

    assert Status.destroy_status(@conn, 153_452)
  end

  test "reblogs and unreblogs a status" do
    expect(Hunter.ApiMock, :reblog, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452", reblogged: true}
    end)

    expect(Hunter.ApiMock, :unreblog, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452", reblogged: false}
    end)

    assert %Status{reblogged: true} = Status.reblog(@conn, 153_452)
    assert %Status{reblogged: false} = Status.unreblog(@conn, 153_452)
  end

  test "favourites and unfavourites a status" do
    expect(Hunter.ApiMock, :favourite, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452", favourited: true}
    end)

    expect(Hunter.ApiMock, :unfavourite, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452", favourited: false}
    end)

    assert %Status{favourited: true} = Status.favourite(@conn, 153_452)
    assert %Status{favourited: false} = Status.unfavourite(@conn, 153_452)
  end

  test "returns authenticated user's favourites" do
    expect(Hunter.ApiMock, :favourites, fn %Hunter.Client{}, [] ->
      [%Status{id: "153452"}]
    end)

    assert [%Status{id: "153452"}] = Status.favourites(@conn)
  end

  test "returns statuses from an account" do
    # Status.statuses/3 converts options with Map.new/1 before delegating
    expect(Hunter.ApiMock, :statuses, fn %Hunter.Client{}, 23_634, %{} ->
      [%Status{id: "153452"}]
    end)

    assert [%Status{}] = Status.statuses(@conn, 23_634)
  end

  test "returns a hashtag timeline" do
    expect(Hunter.ApiMock, :hashtag_timeline, fn %Hunter.Client{}, "elixir", [] ->
      [%Status{id: "153452"}]
    end)

    assert [%Status{}] = Status.hashtag_timeline(@conn, "elixir")
  end

  test "propagates API errors" do
    expect(Hunter.ApiMock, :status, fn %Hunter.Client{}, _id ->
      raise Hunter.Error, reason: "Record not found"
    end)

    assert_raise Hunter.Error, fn -> Status.status(@conn, 0) end
  end
```

Signatures verified against `lib/hunter/status.ex`: only `statuses/3` converts options to a map; all others forward the keyword list unchanged.

- [ ] **Step 2: Run and commit**

Run: `mix test test/hunter/status_test.exs`
Expected: PASS

```bash
git add test/hunter/status_test.exs
git commit -m "cover the full Hunter.Status API surface"
```

### Task 9: `Hunter.Relationship` tests

**Files:**
- Create: `test/hunter/relationship_test.exs`

- [ ] **Step 1: Write the test file**

```elixir
defmodule Hunter.RelationshipTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Relationship

  @conn Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")

  setup :verify_on_exit!

  test "returns relationships to other accounts" do
    expect(Hunter.ApiMock, :relationships, fn %Hunter.Client{}, [8039] ->
      [%Relationship{id: "8039", following: true}]
    end)

    assert [%Relationship{following: true}] = Relationship.relationships(@conn, [8039])
  end

  test "follows and unfollows an account" do
    expect(Hunter.ApiMock, :follow, fn %Hunter.Client{}, 8039 ->
      %Relationship{id: "8039", following: true}
    end)

    expect(Hunter.ApiMock, :unfollow, fn %Hunter.Client{}, 8039 ->
      %Relationship{id: "8039", following: false}
    end)

    assert %Relationship{following: true} = Relationship.follow(@conn, 8039)
    assert %Relationship{following: false} = Relationship.unfollow(@conn, 8039)
  end

  test "blocks and unblocks an account" do
    expect(Hunter.ApiMock, :block, fn %Hunter.Client{}, 8039 ->
      %Relationship{id: "8039", blocking: true}
    end)

    expect(Hunter.ApiMock, :unblock, fn %Hunter.Client{}, 8039 ->
      %Relationship{id: "8039", blocking: false}
    end)

    assert %Relationship{blocking: true} = Relationship.block(@conn, 8039)
    assert %Relationship{blocking: false} = Relationship.unblock(@conn, 8039)
  end

  test "mutes and unmutes an account" do
    expect(Hunter.ApiMock, :mute, fn %Hunter.Client{}, 8039 ->
      %Relationship{id: "8039", muting: true}
    end)

    expect(Hunter.ApiMock, :unmute, fn %Hunter.Client{}, 8039 ->
      %Relationship{id: "8039", muting: false}
    end)

    assert %Relationship{muting: true} = Relationship.mute(@conn, 8039)
    assert %Relationship{muting: false} = Relationship.unmute(@conn, 8039)
  end
end
```

- [ ] **Step 2: Run and commit**

Run: `mix test test/hunter/relationship_test.exs`
Expected: PASS

```bash
git add test/hunter/relationship_test.exs
git commit -m "add relationship tests"
```

### Task 10: Remaining delegation coverage (Account extras, Report, Result, Context, Attachment, Domain)

**Files:**
- Modify: `test/hunter/account_test.exs`
- Create: `test/hunter/report_test.exs`, `test/hunter/result_test.exs`, `test/hunter/context_test.exs`, `test/hunter/attachment_test.exs`, `test/hunter/domain_test.exs`

- [ ] **Step 1: Extend `test/hunter/account_test.exs`** (append inside the module):

```elixir
  test "updates authenticated user's credentials" do
    expect(Hunter.ApiMock, :update_credentials, fn %Hunter.Client{}, %{note: "new bio"} ->
      %Account{username: "milmazz", note: "new bio"}
    end)

    assert %Account{note: "new bio"} = Account.update_credentials(@conn, %{note: "new bio"})
  end

  test "searches for accounts" do
    expect(Hunter.ApiMock, :search_account, fn %Hunter.Client{}, %{q: "milmazz"} ->
      [%Account{username: "milmazz"}]
    end)

    assert [%Account{username: "milmazz"}] = Account.search_account(@conn, %{q: "milmazz"})
  end

  test "returns blocked accounts" do
    expect(Hunter.ApiMock, :blocks, fn %Hunter.Client{}, [] ->
      [%Account{username: "spammer"}]
    end)

    assert [%Account{username: "spammer"}] = Account.blocks(@conn)
  end

  test "returns follow requests" do
    expect(Hunter.ApiMock, :follow_requests, fn %Hunter.Client{}, [] ->
      [%Account{username: "kadaba"}]
    end)

    assert [%Account{username: "kadaba"}] = Account.follow_requests(@conn)
  end

  test "returns muted accounts" do
    expect(Hunter.ApiMock, :mutes, fn %Hunter.Client{}, [] ->
      [%Account{username: "loud"}]
    end)

    assert [%Account{username: "loud"}] = Account.mutes(@conn)
  end

  test "accepts and rejects follow requests" do
    expect(Hunter.ApiMock, :follow_request_action, 2, fn
      %Hunter.Client{}, 8039, :authorize -> true
      %Hunter.Client{}, 8039, :reject -> true
    end)

    assert Account.accept_follow_request(@conn, 8039)
    assert Account.reject_follow_request(@conn, 8039)
  end
```

Wrapper names verified against `lib/hunter/account.ex:300,314`: `accept_follow_request/2` and `reject_follow_request/2` both delegate to the `follow_request_action` callback.

- [ ] **Step 2: Create the five new test files**

`test/hunter/report_test.exs`:

```elixir
defmodule Hunter.ReportTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Report

  @conn Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")

  setup :verify_on_exit!

  test "returns authenticated user's reports" do
    expect(Hunter.ApiMock, :reports, fn %Hunter.Client{} ->
      [%Report{id: "48914", action_taken: false}]
    end)

    assert [%Report{id: "48914"}] = Report.reports(@conn)
  end

  test "reports an account" do
    expect(Hunter.ApiMock, :report, fn %Hunter.Client{}, 8039, [153_452], "spam" ->
      %Report{id: "48915", action_taken: false}
    end)

    assert %Report{id: "48915"} = Report.report(@conn, 8039, [153_452], "spam")
  end
end
```

`test/hunter/result_test.exs`:

```elixir
defmodule Hunter.ResultTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Result

  @conn Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")

  setup :verify_on_exit!

  test "searches for content" do
    expect(Hunter.ApiMock, :search, fn %Hunter.Client{}, "elixir", [] ->
      %Result{accounts: [], statuses: [], hashtags: ["elixir"]}
    end)

    assert %Result{hashtags: ["elixir"]} = Result.search(@conn, "elixir")
  end
end
```

`test/hunter/context_test.exs`:

```elixir
defmodule Hunter.ContextTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Context

  @conn Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")

  setup :verify_on_exit!

  test "returns the context of a status" do
    expect(Hunter.ApiMock, :status_context, fn %Hunter.Client{}, 153_452 ->
      %Context{ancestors: [], descendants: [%Hunter.Status{id: "153453"}]}
    end)

    assert %Context{descendants: [%Hunter.Status{}]} = Context.status_context(@conn, 153_452)
  end
end
```

`test/hunter/attachment_test.exs`:

```elixir
defmodule Hunter.AttachmentTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Attachment

  @conn Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")

  setup :verify_on_exit!

  test "uploads a media file" do
    expect(Hunter.ApiMock, :upload_media, fn %Hunter.Client{}, "image.png", [] ->
      %Attachment{id: "22345792", type: "image"}
    end)

    assert %Attachment{type: "image"} = Attachment.upload_media(@conn, "image.png")
  end
end
```

`test/hunter/domain_test.exs`:

```elixir
defmodule Hunter.DomainTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Domain

  @conn Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")

  setup :verify_on_exit!

  test "returns blocked domains" do
    expect(Hunter.ApiMock, :blocked_domains, fn %Hunter.Client{}, [] ->
      ["spam.example"]
    end)

    assert ["spam.example"] = Domain.blocked_domains(@conn)
  end

  test "blocks and unblocks a domain" do
    expect(Hunter.ApiMock, :block_domain, fn %Hunter.Client{}, "spam.example" -> true end)
    expect(Hunter.ApiMock, :unblock_domain, fn %Hunter.Client{}, "spam.example" -> true end)

    assert Domain.block_domain(@conn, "spam.example")
    assert Domain.unblock_domain(@conn, "spam.example")
  end
end
```

- [ ] **Step 3: Run the full suite, lint, commit**

Run: `mix test && mix format --check-formatted && mix credo --strict`
Expected: PASS. Fix any expectation-head mismatches against the real signatures (read the entity module, not the test, as the source of truth).

```bash
git add test/hunter
git commit -m "cover remaining API surface: account extras, report, result, context, attachment, domain"
```

### Task 11: Open PR2

- [ ] **Step 1: Push and create the stacked PR**

```bash
git push -u origin unit-test-suite
gh pr create --base ci-workflow --title "Robust unit test suite (issue #13)" --body "$(cat <<'EOF'
Part 2 of 3 stacked PRs (base: #<PR1 number>) implementing docs/superpowers/specs/2026-07-06-ci-and-test-suite-design.md.

- Extracts JSON→struct decoding into `Hunter.Api.Transformer` and covers every entity with real Mastodon JSON fixtures (nested structs included — previously context/result/notification left inner entities as plain maps)
- Refactors `Hunter.Api.Request` so body building, header merging, and response handling are pure and unit-tested
- Extends Mox delegation tests to the full API surface: Status, Relationship, Account extras, Report, Result, Context, Attachment, Domain, plus error propagation
- Adds `Hunter.Client` / `Hunter.Error` tests

Closes #13.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Replace `#<PR1 number>` with the actual number from Task 3.

- [ ] **Step 2: Watch checks**

Run: `gh pr checks --watch`
Expected: green.

---

# PR3: Integration suite + Mastodon-in-Docker CI (branch `integration-tests`, base `unit-test-suite`)

```bash
git checkout unit-test-suite && git checkout -b integration-tests
```

### Task 12: Integration harness (exclusion + case template)

**Files:**
- Modify: `test/test_helper.exs`
- Create: `test/support/integration_case.ex`
- Modify: `mix.exs` (`elixirc_paths` must include `test/support` in test env)

**Interfaces:**
- Produces: `Hunter.IntegrationCase` — `use`-able case that provides `conn` (user 1) and `conn2` (user 2) in the test context, plus `eventually/2` for sidekiq-async assertions. Reads `HUNTER_BASE_URL`, `HUNTER_TOKEN`, `HUNTER_TOKEN2`.

- [ ] **Step 1: Update `test/test_helper.exs`**

```elixir
ExUnit.start(exclude: [:integration])

Mox.defmock(Hunter.ApiMock, for: Hunter.Api)
Application.put_env(:hunter, :hunter_api, Hunter.ApiMock)

ExUnit.after_suite(fn _ ->
  "../tmp"
  |> Path.expand(__DIR__)
  |> File.rm_rf()
end)
```

(Only the first line changes: `:integration` excluded by default; `mix test --only integration` overrides it.)

- [ ] **Step 2: Update `mix.exs` elixirc_paths**

Replace `elixirc_paths: ["lib"]` with:

```elixir
      elixirc_paths: elixirc_paths(Mix.env()),
```

and add inside the module:

```elixir
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
```

- [ ] **Step 3: Create `test/support/integration_case.ex`**

```elixir
defmodule Hunter.IntegrationCase do
  @moduledoc """
  Case template for tests that run against a real Mastodon server.

  Requires `HUNTER_BASE_URL`, `HUNTER_TOKEN` and `HUNTER_TOKEN2` to be set;
  run via `mix test --only integration` so the mock-based unit suite does not
  run concurrently (the API adapter is swapped globally).
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Hunter.IntegrationCase, only: [eventually: 1, eventually: 2]

      @moduletag :integration
      @moduletag timeout: 120_000
    end
  end

  setup_all do
    base_url = fetch_env!("HUNTER_BASE_URL")
    token = fetch_env!("HUNTER_TOKEN")
    token2 = fetch_env!("HUNTER_TOKEN2")

    previous_api = Application.get_env(:hunter, :hunter_api)
    previous_http = Application.get_env(:hunter, :http_options)

    Application.put_env(:hunter, :hunter_api, Hunter.Api.HTTPClient)
    # The CI stack fronts Mastodon with a self-signed TLS cert.
    Application.put_env(:hunter, :http_options, hackney: [:insecure], recv_timeout: 30_000)

    on_exit(fn ->
      Application.put_env(:hunter, :hunter_api, previous_api)
      Application.put_env(:hunter, :http_options, previous_http)
    end)

    {:ok,
     conn: Hunter.Client.new(base_url: base_url, bearer_token: token),
     conn2: Hunter.Client.new(base_url: base_url, bearer_token: token2)}
  end

  @doc """
  Retries `fun` until it returns without raising, for async server-side
  effects (sidekiq). Raises the last error after `attempts` tries.
  """
  def eventually(fun, attempts \\ 30)

  def eventually(fun, 1), do: fun.()

  def eventually(fun, attempts) do
    fun.()
  rescue
    _ ->
      Process.sleep(1_000)
      eventually(fun, attempts - 1)
  end

  defp fetch_env!(name) do
    System.get_env(name) ||
      raise """
      #{name} is not set.

      Integration tests need a running Mastodon server. Locally:

          ./scripts/ci/setup_mastodon.sh
          source scripts/ci/.env.hunter
          mix test --only integration
      """
  end
end
```

- [ ] **Step 4: Verify the unit suite still passes and integration is skipped**

Run: `mix test`
Expected: same pass count as before, output shows `Excluding tags: [:integration]`.

- [ ] **Step 5: Commit**

```bash
git add test/test_helper.exs test/support/integration_case.ex mix.exs
git commit -m "add integration case template gated behind --only integration"
```

### Task 13: Integration tests

**Files:**
- Create: `test/integration/mastodon_test.exs`

**Interfaces:**
- Consumes: `Hunter.IntegrationCase` (Task 12). Server contract (Task 14): user 1 = `hunter`, user 2 = `kadaba`, both confirmed/approved, tokens with `read write follow` scopes.

Spec deviation, intentional: the flow uses `Account.search_account` (endpoint still present in Mastodon 4.x) instead of `Result.search`, because `Hunter.Api.HTTPClient` targets `/api/v1/search`, which modern Mastodon removed (v2 only). File a follow-up issue for migrating `Result.search` to `/api/v2/search` when PR3 goes up — that's exactly the API drift these tests exist to catch.

- [ ] **Step 1: Write `test/integration/mastodon_test.exs`**

```elixir
defmodule Hunter.Integration.MastodonTest do
  use Hunter.IntegrationCase, async: false

  alias Hunter.{Account, Attachment, Instance, Notification, Relationship, Status}

  @png Base.decode64!(
         "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
       )

  test "verifies credentials of both provisioned users", %{conn: conn, conn2: conn2} do
    assert %Account{username: "hunter"} = Account.verify_credentials(conn)
    assert %Account{username: "kadaba"} = Account.verify_credentials(conn2)
  end

  test "fetches instance information", %{conn: conn} do
    assert %Instance{uri: uri, version: version} = Instance.instance_info(conn)
    assert is_binary(uri)
    assert is_binary(version)
  end

  test "status lifecycle: create, fetch, favourite, reblog, destroy", %{
    conn: conn,
    conn2: conn2
  } do
    text = "hunter integration test #hunterci"

    status = Status.create_status(conn, text)
    assert %Status{id: id, content: content} = status
    assert content =~ "hunterci"

    assert %Status{id: ^id} = Status.status(conn, id)

    assert %Status{favourited: true} = Status.favourite(conn2, id)
    assert %Status{} = Status.unfavourite(conn2, id)

    assert %Status{reblogged: true} = Status.reblog(conn2, id)
    assert %Status{} = Status.unreblog(conn2, id)

    assert Status.destroy_status(conn, id)

    # deletion is synchronous; a subsequent fetch is a 404, which request! raises
    assert_raise Hunter.Error, fn -> Status.status(conn, id) end
  end

  test "statuses appear on the local public timeline", %{conn: conn} do
    %Status{id: id} = Status.create_status(conn, "timeline check #hunterci")

    eventually(fn ->
      timeline = Status.public_timeline(conn, local: true)
      assert Enum.any?(timeline, &(&1.id == id))
    end)

    Status.destroy_status(conn, id)
  end

  test "follow, relationship, and notifications across accounts", %{conn: conn, conn2: conn2} do
    %Account{username: "hunter"} = Account.verify_credentials(conn)
    %Account{id: id2} = Account.verify_credentials(conn2)

    assert %Relationship{following: true} = Relationship.follow(conn, id2)
    assert [%Relationship{following: true}] = Relationship.relationships(conn, [id2])

    %Status{id: status_id} = Status.create_status(conn2, "hello @hunter #hunterci")

    eventually(fn ->
      notifications = Notification.notifications(conn)

      assert Enum.any?(notifications, fn n ->
               n.type == "mention" and n.account.username == "kadaba"
             end)
    end)

    assert %Relationship{following: false} = Relationship.unfollow(conn, id2)
    Status.destroy_status(conn2, status_id)
  end

  test "searches for accounts", %{conn: conn} do
    accounts = Account.search_account(conn, %{q: "kadaba"})

    assert Enum.any?(accounts, &(&1.username == "kadaba"))
  end

  test "uploads media and attaches it to a status", %{conn: conn} do
    path = Path.join(System.tmp_dir!(), "hunter-integration.png")
    File.write!(path, @png)

    assert %Attachment{id: media_id, type: "image"} = Attachment.upload_media(conn, path)

    %Status{id: id, media_attachments: attachments} =
      eventually(fn ->
        Status.create_status(conn, "media test #hunterci", media_ids: [media_id])
      end)

    assert Enum.any?(attachments, &(&1.id == media_id))
    Status.destroy_status(conn, id)
  after
    File.rm(Path.join(System.tmp_dir!(), "hunter-integration.png"))
  end
end
```

Before finalizing, read `lib/hunter/status.ex:105` for `create_status` options handling (the `media_ids` option) and `lib/hunter/attachment.ex:57` for the upload signature; adjust call shapes to match the real code.

- [ ] **Step 2: Verify compile + unit suite unaffected**

Run: `mix test`
Expected: integration tests listed as excluded; everything else passes. (Live verification happens in Task 14.)

- [ ] **Step 3: Commit**

```bash
git add test/integration/mastodon_test.exs
git commit -m "add integration suite against a live Mastodon server"
```

### Task 14: Mastodon docker stack + provisioning script, verified locally

**Files:**
- Create: `docker-compose.ci.yml`, `scripts/ci/nginx.conf`, `scripts/ci/setup_mastodon.sh` (chmod +x)
- Modify: `.gitignore` (ignore generated env/cert files), `CONTRIBUTING.md` (how to run integration tests)

**Interfaces:**
- Produces: script writes `scripts/ci/.env.hunter` containing `HUNTER_BASE_URL=https://localhost:3000`, `HUNTER_TOKEN=…`, `HUNTER_TOKEN2=…` (and appends the same to `$GITHUB_ENV` when set). Users: `hunter` / `kadaba` per Task 13's contract.

- [ ] **Step 1: Write `docker-compose.ci.yml`**

```yaml
# CI/local integration-test stack. Mastodon production mode forces SSL, so an
# nginx sidecar terminates TLS with a self-signed cert and forwards
# X-Forwarded-Proto: https.
services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "postgres"]
      interval: 2s
      timeout: 5s
      retries: 30

  redis:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 2s
      timeout: 5s
      retries: 30

  web:
    image: ghcr.io/mastodon/mastodon:v4.3.8
    env_file: scripts/ci/.env.mastodon
    command: bundle exec puma -C config/puma.rb
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "curl -fsS http://localhost:3000/health || exit 1"]
      interval: 5s
      timeout: 5s
      retries: 60

  sidekiq:
    image: ghcr.io/mastodon/mastodon:v4.3.8
    env_file: scripts/ci/.env.mastodon
    command: bundle exec sidekiq
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy

  nginx:
    image: nginx:1.27-alpine
    ports:
      - "3000:3000"
    volumes:
      - ./scripts/ci/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./scripts/ci/certs:/etc/nginx/certs:ro
    depends_on:
      web:
        condition: service_healthy
```

- [ ] **Step 2: Write `scripts/ci/nginx.conf`**

```nginx
events {}

http {
  server {
    listen 3000 ssl;

    ssl_certificate /etc/nginx/certs/localhost.crt;
    ssl_certificate_key /etc/nginx/certs/localhost.key;

    client_max_body_size 40m;

    location / {
      proxy_pass http://web:3000;
      proxy_set_header Host localhost;
      proxy_set_header X-Forwarded-Proto https;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Real-IP $remote_addr;
    }
  }
}
```

- [ ] **Step 3: Write `scripts/ci/setup_mastodon.sh`**

```bash
#!/usr/bin/env bash
# Boots a disposable Mastodon (docker-compose.ci.yml), provisions two users
# with OAuth tokens, and writes scripts/ci/.env.hunter with the env vars the
# integration suite needs. Idempotent: safe to re-run.
set -euo pipefail

cd "$(dirname "$0")/../.."
COMPOSE="docker compose -f docker-compose.ci.yml"
CI_DIR=scripts/ci
MASTODON_ENV="$CI_DIR/.env.mastodon"
HUNTER_ENV="$CI_DIR/.env.hunter"

# 1. Secrets (generated once; arbitrary values are fine for a throwaway box,
#    but VAPID keys must be a real EC pair, so those come from the rake task).
if [ ! -f "$MASTODON_ENV" ]; then
  cat > "$MASTODON_ENV" <<EOF
RAILS_ENV=production
NODE_ENV=production
LOCAL_DOMAIN=localhost
DB_HOST=db
DB_PORT=5432
DB_USER=postgres
DB_PASS=postgres
DB_NAME=mastodon_production
REDIS_HOST=redis
REDIS_PORT=6379
ES_ENABLED=false
S3_ENABLED=false
RAILS_LOG_LEVEL=warn
SECRET_KEY_BASE=$(openssl rand -hex 64)
OTP_SECRET=$(openssl rand -hex 64)
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=$(openssl rand -hex 32)
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=$(openssl rand -hex 32)
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=$(openssl rand -hex 32)
EOF
  $COMPOSE run --rm web bundle exec rake mastodon:webpush:generate_vapid_key >> "$MASTODON_ENV"
fi

# 2. Self-signed cert for the nginx TLS front.
mkdir -p "$CI_DIR/certs"
if [ ! -f "$CI_DIR/certs/localhost.crt" ]; then
  openssl req -x509 -newkey rsa:2048 -nodes -days 30 \
    -keyout "$CI_DIR/certs/localhost.key" \
    -out "$CI_DIR/certs/localhost.crt" \
    -subj "/CN=localhost"
fi

# 3. Database + app boot.
$COMPOSE up -d db redis
$COMPOSE run --rm web bundle exec rails db:prepare
$COMPOSE up -d web sidekiq nginx

echo "Waiting for Mastodon to answer..."
for _ in $(seq 1 60); do
  if curl -fsSk https://localhost:3000/health > /dev/null 2>&1; then
    break
  fi
  sleep 2
done
curl -fsSk https://localhost:3000/health > /dev/null

# 4. Users + OAuth tokens.
create_user() {
  # tootctl exits non-zero if the user exists; tolerate for idempotency.
  $COMPOSE exec -T web bin/tootctl accounts create "$1" \
    --email "$1@example.com" --confirmed --approve > /dev/null 2>&1 || true
}
create_user hunter
create_user kadaba

mint_token() {
  $COMPOSE exec -T web bin/rails runner "
    app = Doorkeeper::Application.find_or_create_by!(name: 'hunter-ci') do |a|
      a.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
      a.scopes = 'read write follow'
    end
    user = User.find_by!(email: '$1@example.com')
    token = Doorkeeper::AccessToken.find_or_create_by!(
      application_id: app.id, resource_owner_id: user.id, revoked_at: nil
    ) { |t| t.scopes = app.scopes.to_s }
    puts token.token
  " | tr -d '[:space:]'
}

TOKEN1=$(mint_token hunter)
TOKEN2=$(mint_token kadaba)

cat > "$HUNTER_ENV" <<EOF
export HUNTER_BASE_URL=https://localhost:3000
export HUNTER_TOKEN=$TOKEN1
export HUNTER_TOKEN2=$TOKEN2
EOF

if [ -n "${GITHUB_ENV:-}" ]; then
  {
    echo "HUNTER_BASE_URL=https://localhost:3000"
    echo "HUNTER_TOKEN=$TOKEN1"
    echo "HUNTER_TOKEN2=$TOKEN2"
  } >> "$GITHUB_ENV"
fi

echo "Mastodon ready at https://localhost:3000 (users: hunter, kadaba)"
echo "Run: source $HUNTER_ENV && mix test --only integration"
```

```bash
chmod +x scripts/ci/setup_mastodon.sh
```

- [ ] **Step 4: Ignore generated files**

Append to `.gitignore`:

```
/scripts/ci/.env.mastodon
/scripts/ci/.env.hunter
/scripts/ci/certs/
```

- [ ] **Step 5: Run it locally and drive the suite green**

Run:

```bash
./scripts/ci/setup_mastodon.sh
source scripts/ci/.env.hunter   # bash/zsh; for fish: use `bash -c '...'` or export manually
mix test --only integration
```

Expected: all integration tests pass. This step WILL surface surprises (image tag, tootctl flags, Doorkeeper API, endpoint drift, sidekiq timing) — iterate with systematic-debugging until green. Budget real time for it; do not skip local verification and hope CI works. If Docker is unavailable locally, say so explicitly in the task report and rely on Step 5 of Task 15 (CI iteration) instead.

Teardown between attempts when needed: `docker compose -f docker-compose.ci.yml down -v` (add `rm scripts/ci/.env.mastodon` to regenerate secrets).

- [ ] **Step 6: Document in CONTRIBUTING.md**

Append a section:

```markdown
## Running the test suite

* `mix test` — fast, offline unit suite (integration tests are excluded).
* Integration tests run against a real Mastodon server:

      ./scripts/ci/setup_mastodon.sh
      source scripts/ci/.env.hunter
      mix test --only integration

  Requires Docker. The stack is disposable: `docker compose -f docker-compose.ci.yml down -v`.
  You can also point the suite at any instance you own by exporting
  `HUNTER_BASE_URL`, `HUNTER_TOKEN` and `HUNTER_TOKEN2` yourself.
```

- [ ] **Step 7: Commit**

```bash
git add docker-compose.ci.yml scripts/ci/nginx.conf scripts/ci/setup_mastodon.sh .gitignore CONTRIBUTING.md
git commit -m "add disposable Mastodon stack for integration tests"
```

### Task 15: CI integration job + PR3

**Files:**
- Modify: `.github/workflows/ci.yml` (append job)

- [ ] **Step 1: Append the `integration` job to `.github/workflows/ci.yml`**

```yaml
  integration:
    name: Integration (real Mastodon)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          version-file: .tool-versions
          version-type: strict
      - uses: actions/cache@v4
        with:
          path: |
            deps
            _build
          key: mix-integration-${{ runner.os }}-${{ hashFiles('.tool-versions', 'mix.lock') }}
          restore-keys: |
            mix-integration-${{ runner.os }}-
      - run: mix deps.get
      - run: mix compile --warnings-as-errors
      - name: Boot Mastodon and provision tokens
        run: ./scripts/ci/setup_mastodon.sh
      - name: Run integration tests
        run: mix test --only integration
      - name: Dump Mastodon logs on failure
        if: failure()
        run: docker compose -f docker-compose.ci.yml logs --tail 200
```

- [ ] **Step 2: Commit and open PR3**

```bash
git add .github/workflows/ci.yml
git commit -m "run integration suite against a real Mastodon server in CI"
git push -u origin integration-tests
gh pr create --base unit-test-suite --title "Integration tests against a real Mastodon server" --body "$(cat <<'EOF'
Part 3 of 3 stacked PRs (base: #<PR2 number>) implementing docs/superpowers/specs/2026-07-06-ci-and-test-suite-design.md.

- `test/integration/` suite (tagged, excluded from `mix test` by default), driven by `HUNTER_BASE_URL`/`HUNTER_TOKEN`/`HUNTER_TOKEN2`
- Disposable Mastodon stack (`docker-compose.ci.yml` + `scripts/ci/setup_mastodon.sh`): postgres, redis, mastodon v4.3.8 (pinned), sidekiq, nginx TLS front (production Mastodon forces SSL)
- CI `integration` job boots the stack and runs the suite on every PR
- Flow covered: credentials, instance info, status lifecycle, favourite/reblog, timelines, follow + notifications across two accounts, account search, media upload

Known API drift found while writing this (follow-up issues): `/api/v1/search` (used by `Result.search`) and `/api/v1/follows` (`Account.follow_by_uri`) were removed in modern Mastodon.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Replace `#<PR2 number>` with the actual number.

- [ ] **Step 3: Watch checks; iterate in CI if needed**

Run: `gh pr checks --watch`
Expected: all jobs green, including `Integration (real Mastodon)`. CI failures in the integration job: pull logs via the failure step's output (`gh run view --log-failed`), fix, push. Common suspects: image tag availability on ghcr, disk/memory on the runner, timing (raise `eventually` attempts or healthcheck retries).

- [ ] **Step 4: File the API-drift follow-up issue**

```bash
gh issue create --title "Migrate Result.search to /api/v2/search and drop removed endpoints" --body "$(cat <<'EOF'
Found while building the integration suite (spec: docs/superpowers/specs/2026-07-06-ci-and-test-suite-design.md):

- `Hunter.Api.HTTPClient.search/3` targets `/api/v1/search`, removed in Mastodon 3.0+ (use `/api/v2/search`; note `hashtags` become objects instead of strings)
- `Hunter.Api.HTTPClient.follow_by_uri/2` targets `/api/v1/follows`, removed in Mastodon 4.0 (use `POST /api/v1/accounts/:id/follow` after resolving via search)
- `GET /api/v1/reports` was also removed

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Merge order

PR1 → merge to `main`; retarget PR2 to `main` (GitHub does this automatically on branch deletion) → merge → retarget PR3 → merge. Use the superpowers:finishing-a-development-branch skill at each merge point.
