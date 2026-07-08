# Modern-Mastodon Endpoint Fixes Implementation Plan (#118)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the five endpoints that are broken or deprecated on modern Mastodon (cards, follow requests, notification dismiss, media v2, instance v2) before the 0.6.0 release. Fixes #118.

**Architecture:** Each part is an isolated change to `Hunter.Api.HTTPClient` plus its entity/behaviour/test surface. Cards move from a removed endpoint to an embedded `Status.card` field; follow requests get the documented per-id paths and their real `Relationship` return; dismiss gets the documented path; media and instance move to their v2 endpoints (instance with a top-level struct reshape). Live integration coverage lands in one task at the end, exercising every changed path against real Mastodon.

**Tech Stack:** Elixir/ExUnit, Mox, Poison `as:` decoding, the docker-compose Mastodon v4.3.8 stack.

**Spec:** `docs/superpowers/specs/2026-07-08-endpoint-fixes-design.md`

## Global Constraints

- Branch `fix-api-drift-4x` (exists off `main`, spec committed at 38c2248). One PR, base `main`. **Do NOT merge the PR — the user reviews manually.**
- Every commit passes `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`; `mix dialyzer` once in Task 7 (struct + callback changes).
- Live verification in Task 6: `./scripts/ci/setup_mastodon.sh` then `bash -c 'source scripts/ci/.env.hunter && mix test --only integration'` — expect **13 tests, 0 failures** (12 existing + the follow-request test; the dismiss step folds into an existing test).
- Commit messages end with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`; the PR body ends with `🤖 Generated with [Claude Code](https://claude.com/claude-code)` and says `Fixes #118.`
- This branch will conflict with open PR #117 only in CHANGELOG.md — expected; do not try to avoid it.

---

### Task 1: preview cards — embedded field in, removed endpoint out (TDD)

**Files:**
- Modify: `test/fixtures/status.json`, `test/hunter/api/transformer_test.exs`, `lib/hunter/status.ex`, `lib/hunter/api/transformer.ex`
- Modify (removals): `lib/hunter.ex`, `lib/hunter/card.ex`, `lib/hunter/api.ex`, `lib/hunter/api/http_client.ex`
- Delete: `test/hunter/card_test.exs`

**Interfaces:**
- Produces: `Hunter.Status` struct field `card: Hunter.Card.t() | nil`; `card_by_status` gone from the public API and the `Hunter.Api` behaviour.

- [ ] **Step 1 (red): fixture + assertions.** In `test/fixtures/status.json`, add after the `"application"` object (inside the top-level object):

```json
  "card": {
    "url": "https://elixir-lang.org/",
    "title": "The Elixir programming language",
    "description": "Elixir is a dynamic, functional language.",
    "type": "link",
    "image": "https://mastodon.example/preview_cards/image.png"
  }
```

In `test/hunter/api/transformer_test.exs`, inside `test "decodes a status with nested entities"`, add after the tags assertion:

```elixir
    assert %Hunter.Card{title: "The Elixir programming language", type: "link"} = status.card
```

- [ ] **Step 2: verify red**

Run: `mix test test/hunter/api/transformer_test.exs`
Expected: FAIL — `card` is not a key of `Hunter.Status` (or decodes as a plain map once the field exists; the KeyError comes first).

- [ ] **Step 3: add the field.** `lib/hunter/status.ex`: append `:card` to the `defstruct` list, add `card: Hunter.Card.t() | nil` to `@type t`, and add `* card - preview card generated for links in the status, if any` to the moduledoc Fields list.

- [ ] **Step 4: decode it.** In `lib/hunter/api/transformer.ex`'s `status_nested_struct/0`, add `card: %Hunter.Card{}` to the `%Hunter.Status{…}` map.

- [ ] **Step 5: remove the dead endpoint.** Each removal takes the whole block (doc + spec/callback + function):
  - `lib/hunter.ex`: the `card_by_status` `@doc`/`@spec`/`defdelegate` block.
  - `lib/hunter/card.ex`: the `card_by_status` block (around lines 60-78; the doc, `@spec`, and `def`). The struct, moduledoc, and `@type` stay — update the moduledoc if it mentions retrieving cards by status. Remove the now-unused `alias Hunter.Config` if it becomes unused (compile with `--warnings-as-errors` will tell you).
  - `lib/hunter/api.ex`: the `@callback card_by_status(...)` block (around lines 634-643).
  - `lib/hunter/api/http_client.ex`: the `card_by_status/2` function (around lines 286-290).
  - `lib/hunter/api/transformer.ex`: the `def transform(body, :card), do: ...` clause (now orphaned).
  - `test/hunter/api/transformer_test.exs`: the `test "decodes a card"` block (card decoding is now covered through the status fixture).
  - Delete `test/hunter/card_test.exs` (its only test mocks the removed function).

- [ ] **Step 6: verify green + gate**

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`
Expected: all green; `git grep -n "card_by_status" -- lib test` returns nothing.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "embed preview cards in Status, drop the removed card endpoint

BREAKING: GET /api/v1/statuses/:id/card was removed in Mastodon 3.0;
the card ships inside the Status entity. Hunter.Status gains a card
field; card_by_status is gone (#118).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 2: follow requests — documented paths, Relationship return (TDD)

**Files:**
- Modify: `lib/hunter/api/http_client.ex:64-68`, `lib/hunter/api.ex` (callback around line 168-180), `lib/hunter/account.ex` (both wrapper `@spec`s, around lines 299-315), `lib/hunter.ex` (both delegate `@spec`s, around lines 167-180)
- Test: `test/hunter/account_test.exs` (the "accepts and rejects follow requests" test)

**Interfaces:**
- Produces: `accept_follow_request/2` and `reject_follow_request/2` returning `Hunter.Relationship.t()`; `follow_request_action` callback spec `(conn, id, action) :: Hunter.Relationship.t()`.

- [ ] **Step 1 (red): update the Mox test.** Replace the body of `test "accepts and rejects follow requests"` in `test/hunter/account_test.exs`:

```elixir
    expect(Hunter.ApiMock, :follow_request_action, 2, fn
      %Hunter.Client{}, 8039, :authorize -> %Hunter.Relationship{id: "8039", followed_by: true}
      %Hunter.Client{}, 8039, :reject -> %Hunter.Relationship{id: "8039", followed_by: false}
    end)

    assert %Hunter.Relationship{followed_by: true} = Account.accept_follow_request(@conn, 8039)
    assert %Hunter.Relationship{followed_by: false} = Account.reject_follow_request(@conn, 8039)
```

This is red only in spirit (the wrappers pass anything through) — the REAL red is dialyzer disagreeing with the old `boolean` specs after Step 3; the ordering here exists to pin the new contract before touching specs.

- [ ] **Step 2: fix the endpoint.** `lib/hunter/api/http_client.ex`:

```elixir
  def follow_request_action(conn, id, action) when action in [:authorize, :reject] do
    "/api/v1/follow_requests/#{id}/#{action}"
    |> process_url(conn)
    |> request!(:relationship, :post, [], conn)
  end
```

- [ ] **Step 3: fix the specs.** All return types `boolean` → `Hunter.Relationship.t()`:
  - `lib/hunter/api.ex`: the `@callback follow_request_action(...)` return type.
  - `lib/hunter/account.ex`: `@spec accept_follow_request(...)` and `@spec reject_follow_request(...)`.
  - `lib/hunter.ex`: the same two delegate `@spec`s. Update the three `@doc` blocks if they promise a boolean.

- [ ] **Step 4: gate + commit**

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`

```bash
git add -A
git commit -m "use the documented follow_requests authorize/reject endpoints

BREAKING: the previous POST /api/v1/follow_requests/:action with an id
body matched no Mastodon version; the documented per-id paths return a
Relationship, and the wrappers' specs now say so (#118).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 3: notification dismiss path

**Files:**
- Modify: `lib/hunter/api/http_client.ex:262-266`

- [ ] **Step 1: fix the path.**

```elixir
  def clear_notification(conn, id) do
    "/api/v1/notifications/#{id}/dismiss"
    |> process_url(conn)
    |> request!(nil, :post, [], conn)
  end
```

(The old `/api/v1/notifications/dismiss/#{id}` matches no server version. Live proof lands in Task 6.)

- [ ] **Step 2: gate + commit**

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`

```bash
git add lib/hunter/api/http_client.ex
git commit -m "fix the notification dismiss path

POST /api/v1/notifications/:id/dismiss is the documented form; the
implemented /notifications/dismiss/:id matched no version (#118).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 4: media upload moves to v2

**Files:**
- Modify: `lib/hunter/api/http_client.ex` (the `upload_media/3` URL, around line 97), `lib/hunter/attachment.ex` (the `upload_media/3` `@doc`), `lib/hunter.ex` (the `upload_media` delegate `@doc`)

- [ ] **Step 1: endpoint.** In `HTTPClient.upload_media/3`, change `"/api/v1/media"` to `"/api/v2/media"`. Multipart handling stays byte-identical.

- [ ] **Step 2: document the async contract.** Add to BOTH `@doc` blocks (`Hunter.Attachment.upload_media/3` and the `Hunter.upload_media` delegate), matching each file's doc style:

```markdown
  **Note:** the v2 media endpoint processes large files asynchronously: the
  returned attachment's `url` may be `nil` until the server finishes
  processing (HTTP 202). The `id` can be attached to a status with
  `create_status` as soon as processing completes.
```

- [ ] **Step 3: gate + commit**

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`

```bash
git add lib/hunter/api/http_client.ex lib/hunter/attachment.ex lib/hunter.ex
git commit -m "upload media via POST /api/v2/media

The v1 endpoint has been deprecated since Mastodon 3.1.3; v2 processes
large files asynchronously (documented on upload_media) (#118).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 5: instance v2 (TDD)

**Files:**
- Modify: `test/fixtures/instance.json`, `test/hunter/api/transformer_test.exs`, `lib/hunter/instance.ex`, `lib/hunter/api/http_client.ex` (the `instance_info/1` URL), `test/hunter/instance_test.exs`

**Interfaces:**
- Produces: reshaped `Hunter.Instance` — `defstruct [:domain, :title, :version, :source_url, :description, :usage, :thumbnail, :languages, :configuration, :registrations, :contact, :rules]`, nested values as plain maps/lists. Task 6's live assertion uses `domain`/`version`.

- [ ] **Step 1 (red): rewrite the fixture.** `test/fixtures/instance.json` becomes:

```json
{
  "domain": "mastodon.example",
  "title": "Mastodon Example",
  "version": "4.3.8",
  "source_url": "https://github.com/mastodon/mastodon",
  "description": "A test instance",
  "usage": {
    "users": { "active_month": 2 }
  },
  "thumbnail": {
    "url": "https://mastodon.example/thumbnail.png"
  },
  "languages": ["en"],
  "configuration": {
    "statuses": { "max_characters": 500 },
    "urls": { "streaming": "wss://mastodon.example" }
  },
  "registrations": {
    "enabled": true,
    "approval_required": false
  },
  "contact": {
    "email": "admin@mastodon.example"
  },
  "rules": [
    { "id": "1", "text": "Be excellent to each other" }
  ]
}
```

Replace `test "decodes an instance"` in `test/hunter/api/transformer_test.exs`:

```elixir
  test "decodes a v2 instance" do
    instance = transform("instance", :instance)

    assert %Hunter.Instance{domain: "mastodon.example", version: "4.3.8"} = instance
    assert instance.contact["email"] == "admin@mastodon.example"
    assert instance.configuration["urls"]["streaming"] == "wss://mastodon.example"
    assert [%{"text" => "Be excellent to each other"}] = instance.rules
  end
```

- [ ] **Step 2: verify red**

Run: `mix test test/hunter/api/transformer_test.exs`
Expected: FAIL — `domain` is not a key of `Hunter.Instance`.

- [ ] **Step 3: reshape the struct.** `lib/hunter/instance.ex`: replace the `defstruct`, `@type t`, and moduledoc Fields list with the v2 top-level shape (every field typed loosely — nested objects are plain maps in this pass, full modeling is #119):

```elixir
  defstruct [
    :domain,
    :title,
    :version,
    :source_url,
    :description,
    :usage,
    :thumbnail,
    :languages,
    :configuration,
    :registrations,
    :contact,
    :rules
  ]
```

with `@type t` fields: `domain: String.t()`, `title: String.t()`, `version: String.t()`, `source_url: String.t()`, `description: String.t()`, `usage: map`, `thumbnail: map`, `languages: [String.t()]`, `configuration: map`, `registrations: map`, `contact: map`, `rules: [map]`.

- [ ] **Step 4: endpoint.** In `HTTPClient.instance_info/1`, change `"/api/v1/instance"` to `"/api/v2/instance"`.

- [ ] **Step 5: update the Mox test.** In `test/hunter/instance_test.exs`, the mock's returned struct and the assertion switch from `uri:`-based fields to `%Hunter.Instance{domain: "example.com", version: "4.3.8"}` (read the file and keep its shape otherwise).

- [ ] **Step 6: gate + commit**

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`

```bash
git add -A
git commit -m "fetch instance information via GET /api/v2/instance

BREAKING: Hunter.Instance reshapes to the v2 entity's top-level fields
(domain, configuration, contact, ...); nested objects decode as plain
maps for now — full modeling is tracked by #119 (#118).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 6: live integration coverage

**Files:**
- Modify: `test/integration/mastodon_test.exs`

**Interfaces:**
- Consumes: `Hunter.IntegrationCase` (`conn`, `conn2`, `eventually/2`); the module's existing `destroy_quietly/2`/`unfollow_quietly/2` helpers; everything Tasks 1-5 produced.

- [ ] **Step 1: instance assertion.** In `test "fetches instance information"`, replace the `uri` pattern with:

```elixir
    assert %Instance{domain: domain, version: version} = Instance.instance_info(conn)
    assert is_binary(domain)
    assert is_binary(version)
```

- [ ] **Step 2: dismiss step.** Rework the notification block in `test "follow, relationship, and notifications across accounts"` so the found notification is captured and dismissed:

```elixir
    notification =
      eventually(fn ->
        notifications = Notification.notifications(conn)

        case Enum.find(notifications, fn n ->
               n.type == "mention" and n.account.username == "kadaba"
             end) do
          nil -> raise "mention notification not delivered yet"
          notification -> notification
        end
      end)

    assert Notification.clear_notification(conn, notification.id)
    refute Enum.any?(Notification.notifications(conn), &(&1.id == notification.id))
```

- [ ] **Step 3: the follow-request test.** Append (add a `lock_quietly`-style net inline — see the helper in Step 4):

```elixir
  test "follow requests against a locked account", %{conn: conn, conn2: conn2} do
    %Account{id: id1} = Account.verify_credentials(conn)
    %Account{id: id2} = Account.verify_credentials(conn2)

    assert %Account{locked: true} = Account.update_credentials(conn2, %{locked: true})
    on_exit(fn -> unlock_quietly(conn2) end)

    assert %Relationship{requested: true, following: false} = Relationship.follow(conn, id2)
    on_exit(fn -> unfollow_quietly(conn, id2) end)

    requesters = Account.follow_requests(conn2)
    assert Enum.any?(requesters, &(&1.id == id1))

    assert %Relationship{followed_by: true} = Account.accept_follow_request(conn2, id1)

    assert %Account{locked: false} = Account.update_credentials(conn2, %{locked: false})
    Relationship.unfollow(conn, id2)
  end
```

- [ ] **Step 4: the unlock helper.** Next to the existing `*_quietly` helpers:

```elixir
  defp unlock_quietly(conn) do
    Account.update_credentials(conn, %{locked: false})
    :ok
  rescue
    Hunter.Error -> :ok
  end
```

Note: `update_credentials` is a PATCH with a map payload — verify the payload key reaches the server as expected (the existing Mox test uses `%{note: ...}`; live behavior is what counts here). If Mastodon rejects `%{locked: true}` via this path, check `docker compose -f docker-compose.ci.yml logs web --tail 50` and report rather than weakening the test.

- [ ] **Step 5: run live**

Run: `./scripts/ci/setup_mastodon.sh && bash -c 'source scripts/ci/.env.hunter && mix test --only integration'`
Expected: **13 tests, 0 failures.** These hit every changed endpoint: instance v2, media v2 (existing test), dismiss, follow-request authorize. Iterate systematically on failures (container logs, one change at a time); do not weaken assertions.

- [ ] **Step 6: unit gate + commit**

Run: `mix test && mix format --check-formatted && mix credo --strict`

```bash
git add test/integration/mastodon_test.exs
git commit -m "cover the fixed endpoints live: instance v2, dismiss, follow requests

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 7: CHANGELOG, dialyzer, PR (no merge)

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: CHANGELOG.** Under `## Unreleased` → `* Breaking changes`, append:

```markdown
    - Removed the `card_by_status` function (`Hunter` and `Hunter.Card`):
      Mastodon 3.0 removed the endpoint. The preview card is now embedded in
      `Hunter.Status` as the `card` field ([#118])
    - `accept_follow_request/2` and `reject_follow_request/2` now call the
      documented per-id endpoints and return a `Hunter.Relationship` instead
      of a boolean; the previous implementation matched no Mastodon version
      and could only fail ([#118])
    - `Hunter.Instance` reshaped to the `GET /api/v2/instance` entity
      (`domain`, `configuration`, `contact`, …); nested objects decode as
      plain maps for now ([#118])
```

Under `* Bug fixes`, append:

```markdown
    - Notification dismissal uses the documented
      `POST /api/v1/notifications/:id/dismiss` path; the previous path
      matched no Mastodon version ([#118])
    - Media uploads use `POST /api/v2/media` (v1 deprecated since Mastodon
      3.1.3); large files process asynchronously and the attachment `url`
      may be `nil` until ready ([#118])
```

Add `[#118]: https://github.com/milmazz/hunter/issues/118` to the link references.

- [ ] **Step 2: dialyzer**

Run: `mix dialyzer`
Expected: clean (callback/spec changes are the risk). Fix findings before pushing.

- [ ] **Step 3: push + PR — do NOT merge**

```bash
git add CHANGELOG.md
git commit -m "document the endpoint fixes in the changelog

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
git push -u origin fix-api-drift-4x
gh pr create --base main --title "Fix endpoints broken or deprecated on modern Mastodon" --body "$(cat <<'EOF'
Fixes #118. Part of the Mastodon 4.6 API parity effort.

- **Cards** (breaking): `card_by_status` removed (endpoint gone since Mastodon 3.0); `Hunter.Status` gains the embedded `card` field
- **Follow requests** (breaking): documented `/follow_requests/:id/authorize|reject` paths; returns `Hunter.Relationship` — the old implementation matched no Mastodon version, covered live for the first time (locked-account flow)
- **Notification dismiss**: documented `/notifications/:id/dismiss` path, exercised live
- **Media v2**: `POST /api/v2/media`; async-processing contract documented on `upload_media`
- **Instance v2** (breaking): `Hunter.Instance` reshaped to the v2 top-level entity; nested modeling deferred to #119

Live integration: 13/13 against Mastodon v4.3.8, including a new locked-account follow-request flow. Password-grant deprecation stays with #126.

Note: conflicts with #117 in CHANGELOG.md only — whichever merges second rebases trivially.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 4: watch checks, report, stop**

Run: `gh pr checks --watch`
Expected: all 5 jobs green. Report status. **Do not merge** — the user reviews manually.
