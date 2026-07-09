# Flatten the Facade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Collapse the three-layer `Hunter` → `Hunter.<Entity>` → `Hunter.Api.HTTPClient` call chain into one deep public module (`Hunter`) and one transport module (`Hunter.Api.Request`), per the approved spec at `docs/superpowers/specs/2026-07-08-flatten-facade-design.md`.

**Architecture:** Two stacked PRs. PR 1 (non-breaking): `Hunter.Api.Request` gains a conn-aware `request!/6`; `HTTPClient`'s endpoint bodies become one-line calls to it. PR 2 (breaking): each `defdelegate` in `hunter.ex` is replaced by the real body copied from `HTTPClient`; entity modules are stripped to pure structs; `HTTPClient` is deleted; tests are retargeted; CHANGELOG + 0.7.0.

**Tech Stack:** Elixir, Req (`~> 0.6`), Poison, Req.Test/Plug for test stubs.

## Global Constraints

- CI gates every commit must survive: `mix compile --warnings-as-errors`, `mix test`, `mix format --check-formatted`, `mix credo --strict`, `mix dialyzer` (run dialyzer at least once per PR before opening it).
- One module per file; folders mirror the module hierarchy (repo convention).
- No `@deprecated` shims: entity endpoint functions are removed outright (spec decision).
- Entity structs, `@type t`, `@derive`, and field `@moduledoc`s are kept unchanged.
- Version bump: `0.6.0` → `0.7.0` (in PR 2 only).
- Behavior is preserved exactly — this is a move, not a rewrite. When in doubt, copy the existing body verbatim.
- Commit messages end with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.

## The Endpoint Inventory

This table is the authoritative checklist for both PRs and the source for the CHANGELOG migration table. Every public `Hunter.*` function keeps its current name, arity, and defaults (they are already defined in `lib/hunter.ex` as `defdelegate`s). "Transform" is the atom passed to `Hunter.Api.Transformer.transform/2`. "Payload" is the 5th argument to the new `request!`. Functions marked **special** have non-uniform bodies written out in full inside the tasks.

| Hunter function | Method | Path | Transform | Payload |
|---|---|---|---|---|
| `verify_credentials(conn)` | GET | `/api/v1/accounts/verify_credentials` | `:account` | `[]` |
| `update_credentials(conn, data)` | PATCH | `/api/v1/accounts/update_credentials` | `:account` | `data` |
| `account(conn, id)` | GET | `/api/v1/accounts/#{id}` | `:account` | `[]` |
| `followers(conn, id, options \\ [])` | GET | `/api/v1/accounts/#{id}/followers` | `:accounts` | `options` |
| `following(conn, id, options \\ [])` | GET | `/api/v1/accounts/#{id}/following` | `:accounts` | `options` |
| `search_account(conn, options)` | GET | `/api/v1/accounts/search` | `:accounts` | **special** (required `:q`, `:limit` default 40) |
| `blocks(conn, options \\ [])` | GET | `/api/v1/blocks` | `:accounts` | `options` |
| `follow_requests(conn, options \\ [])` | GET | `/api/v1/follow_requests` | `:accounts` | `options` |
| `mutes(conn, options \\ [])` | GET | `/api/v1/mutes` | `:accounts` | `options` |
| `accept_follow_request(conn, id)` | POST | `/api/v1/follow_requests/#{id}/authorize` | `:relationship` | `[]` |
| `reject_follow_request(conn, id)` | POST | `/api/v1/follow_requests/#{id}/reject` | `:relationship` | `[]` |
| `reblogged_by(conn, id, options \\ [])` | GET | `/api/v1/statuses/#{id}/reblogged_by` | `:accounts` | `options` |
| `favourited_by(conn, id, options \\ [])` | GET | `/api/v1/statuses/#{id}/favourited_by` | `:accounts` | `options` |
| `relationships(conn, ids)` | GET | `/api/v1/accounts/relationships` | `:relationships` | `%{id: ids}` |
| `follow(conn, id)` | POST | `/api/v1/accounts/#{id}/follow` | `:relationship` | `[]` |
| `unfollow(conn, id)` | POST | `/api/v1/accounts/#{id}/unfollow` | `:relationship` | `[]` |
| `block(conn, id)` | POST | `/api/v1/accounts/#{id}/block` | `:relationship` | `[]` |
| `unblock(conn, id)` | POST | `/api/v1/accounts/#{id}/unblock` | `:relationship` | `[]` |
| `mute(conn, id)` | POST | `/api/v1/accounts/#{id}/mute` | `:relationship` | `[]` |
| `unmute(conn, id)` | POST | `/api/v1/accounts/#{id}/unmute` | `:relationship` | `[]` |
| `create_app(name, redirect_uri, scopes, website, options)` | POST | `/api/v1/apps` | `:application` | **special** (bare base URL, `save?`) |
| `load_credentials(name)` | — | local file read | — | **special** |
| `new(options \\ [])` | — | local struct build | — | **special** |
| `user_agent()` | — | local | — | **special** |
| `log_in(app, username, password, base_url)` | POST | `/oauth/token` | `nil` | **special** (bare base URL) |
| `log_in_oauth(app, oauth_code, base_url)` | POST | `/oauth/token` | `nil` | **special** (bare base URL) |
| `upload_media(conn, file, options \\ [])` | POST | `/api/v2/media` | `:attachment` | **special** (multipart) |
| `media_attachment(conn, id)` | GET | `/api/v1/media/#{id}` | `:attachment` | `[]` |
| `update_media(conn, id, options \\ [])` | PUT | `/api/v1/media/#{id}` | `:attachment` | `Map.new(options)` |
| `delete_media(conn, id)` | DELETE | `/api/v1/media/#{id}` | `:empty` | `[]` |
| `search(conn, query, options \\ [])` | GET | `/api/v2/search` | `:result` | **special** (merge `q`) |
| `create_status(conn, status, options \\ [])` | POST | `/api/v1/statuses` | `:status` or `:scheduled_status` | **special** (idempotency header) |
| `status(conn, id)` | GET | `/api/v1/statuses/#{id}` | `:status` | `[]` |
| `statuses_by_ids(conn, ids)` | GET | `/api/v1/statuses` | `:statuses` | `%{id: ids}` |
| `edit_status(conn, id, status, options \\ [])` | PUT | `/api/v1/statuses/#{id}` | `:status` | `options \|> Keyword.put(:status, status) \|> Map.new()` |
| `status_history(conn, id)` | GET | `/api/v1/statuses/#{id}/history` | `:status_edits` | `[]` |
| `status_source(conn, id)` | GET | `/api/v1/statuses/#{id}/source` | `:status_source` | `[]` |
| `destroy_status(conn, id)` | DELETE | `/api/v1/statuses/#{id}` | `:empty` | `[]` |
| `bookmark(conn, id)` | POST | `/api/v1/statuses/#{id}/bookmark` | `:status` | `[]` |
| `unbookmark(conn, id)` | POST | `/api/v1/statuses/#{id}/unbookmark` | `:status` | `[]` |
| `pin(conn, id)` | POST | `/api/v1/statuses/#{id}/pin` | `:status` | `[]` |
| `unpin(conn, id)` | POST | `/api/v1/statuses/#{id}/unpin` | `:status` | `[]` |
| `mute_conversation(conn, id)` | POST | `/api/v1/statuses/#{id}/mute` | `:status` | `[]` |
| `unmute_conversation(conn, id)` | POST | `/api/v1/statuses/#{id}/unmute` | `:status` | `[]` |
| `bookmarks(conn, options \\ [])` | GET | `/api/v1/bookmarks` | `:statuses` | `options` |
| `translate_status(conn, id, options \\ [])` | POST | `/api/v1/statuses/#{id}/translate` | `:translation` | `Map.new(options)` |
| `reblog(conn, id)` | POST | `/api/v1/statuses/#{id}/reblog` | `:status` | `[]` |
| `unreblog(conn, id)` | POST | `/api/v1/statuses/#{id}/unreblog` | `:status` | `[]` |
| `favourite(conn, id)` | POST | `/api/v1/statuses/#{id}/favourite` | `:status` | `[]` |
| `unfavourite(conn, id)` | POST | `/api/v1/statuses/#{id}/unfavourite` | `:status` | `[]` |
| `favourites(conn, options \\ [])` | GET | `/api/v1/favourites` | `:statuses` | `options` |
| `statuses(conn, account_id, options \\ [])` | GET | `/api/v1/accounts/#{account_id}/statuses` | `:statuses` | `options` |
| `home_timeline(conn, options \\ [])` | GET | `/api/v1/timelines/home` | `:statuses` | `options` |
| `public_timeline(conn, options \\ [])` | GET | `/api/v1/timelines/public` | `:statuses` | `options` |
| `hashtag_timeline(conn, hashtag, options \\ [])` | GET | `/api/v1/timelines/tag/#{hashtag}` | `:statuses` | `options` |
| `list_timeline(conn, list_id, options \\ [])` | GET | `/api/v1/timelines/list/#{list_id}` | `:statuses` | `options` |
| `poll(conn, id)` | GET | `/api/v1/polls/#{id}` | `:poll` | `[]` |
| `vote(conn, id, choices)` | POST | `/api/v1/polls/#{id}/votes` | `:poll` | `%{choices: choices}` |
| `status_context(conn, id)` | GET | `/api/v1/statuses/#{id}/context` | `:context` | `[]` |
| `lists(conn)` | GET | `/api/v1/lists` | `:lists` | `[]` |
| `list(conn, id)` | GET | `/api/v1/lists/#{id}` | `:list` | `[]` |
| `create_list(conn, title, options \\ [])` | POST | `/api/v1/lists` | `:list` | `options \|> Keyword.put(:title, title) \|> Map.new()` |
| `update_list(conn, id, options)` | PUT | `/api/v1/lists/#{id}` | `:list` | `Map.new(options)` |
| `destroy_list(conn, id)` | DELETE | `/api/v1/lists/#{id}` | `:empty` | `[]` |
| `list_accounts(conn, id, options \\ [])` | GET | `/api/v1/lists/#{id}/accounts` | `:accounts` | `options` |
| `add_accounts_to_list(conn, id, account_ids)` | POST | `/api/v1/lists/#{id}/accounts` | `:empty` | `%{account_ids: account_ids}` |
| `remove_accounts_from_list(conn, id, account_ids)` | DELETE | `/api/v1/lists/#{id}/accounts` | `:empty` | `%{account_ids: account_ids}` |
| `account_lists(conn, account_id)` | GET | `/api/v1/accounts/#{account_id}/lists` | `:lists` | `[]` |
| `instance_info(conn)` | GET | `/api/v2/instance` | `:instance` | `[]` |
| `notifications(conn, options \\ [])` | GET | `/api/v1/notifications` | `:notifications` | `options` |
| `notification(conn, id)` | GET | `/api/v1/notifications/#{id}` | `:notification` | `[]` |
| `clear_notifications(conn)` | POST | `/api/v1/notifications/clear` | `:empty` | `[]` |
| `clear_notification(conn, id)` | POST | `/api/v1/notifications/#{id}/dismiss` | `:empty` | `[]` |
| `unread_count(conn)` | GET | `/api/v1/notifications/unread_count` | `nil` | **special** (`\|> Map.fetch!("count")`) |
| `notification_policy(conn)` | GET | `/api/v2/notifications/policy` | `:notification_policy` | `[]` |
| `update_notification_policy(conn, options)` | PATCH | `/api/v2/notifications/policy` | `:notification_policy` | `Map.new(options)` |
| `notification_requests(conn, options \\ [])` | GET | `/api/v1/notifications/requests` | `:notification_requests` | `options` |
| `notification_request(conn, id)` | GET | `/api/v1/notifications/requests/#{id}` | `:notification_request` | `[]` |
| `accept_notification_request(conn, id)` | POST | `/api/v1/notifications/requests/#{id}/accept` | `:empty` | `[]` |
| `dismiss_notification_request(conn, id)` | POST | `/api/v1/notifications/requests/#{id}/dismiss` | `:empty` | `[]` |
| `accept_notification_requests(conn, ids)` | POST | `/api/v1/notifications/requests/accept` | `:empty` | `%{id: ids}` |
| `dismiss_notification_requests(conn, ids)` | POST | `/api/v1/notifications/requests/dismiss` | `:empty` | `%{id: ids}` |
| `notification_requests_merged?(conn)` | GET | `/api/v1/notifications/requests/merged` | `nil` | **special** (`\|> Map.fetch!("merged")`) |
| `grouped_notifications(conn, options \\ [])` | GET | `/api/v2/notifications` | `:grouped_notifications` | `options` |
| `notification_group(conn, group_key)` | GET | `/api/v2/notifications/#{group_key}` | `:grouped_notifications` | `[]` |
| `dismiss_notification_group(conn, group_key)` | POST | `/api/v2/notifications/#{group_key}/dismiss` | `:empty` | `[]` |
| `notification_group_accounts(conn, group_key)` | GET | `/api/v2/notifications/#{group_key}/accounts` | `:accounts` | `[]` |
| `grouped_unread_count(conn)` | GET | `/api/v2/notifications/unread_count` | `nil` | **special** (`\|> Map.fetch!("count")`) |
| `create_push_subscription(conn, subscription, data \\ %{})` | POST | `/api/v1/push/subscription` | `:web_push_subscription` | `%{subscription: subscription, data: data}` |
| `push_subscription(conn)` | GET | `/api/v1/push/subscription` | `:web_push_subscription` | `[]` |
| `update_push_subscription(conn, data)` | PUT | `/api/v1/push/subscription` | `:web_push_subscription` | `%{data: data}` |
| `delete_push_subscription(conn)` | DELETE | `/api/v1/push/subscription` | `:empty` | `[]` |
| `report(conn, account_id, status_ids, comment)` | POST | `/api/v1/reports` | `:report` | `%{account_id: account_id, status_ids: status_ids, comment: comment}` |
| `blocked_domains(conn, options \\ [])` | GET | `/api/v1/domain_blocks` | `nil` | `options` |
| `block_domain(conn, domain)` | POST | `/api/v1/domain_blocks` | `:empty` | `%{domain: domain}` |
| `unblock_domain(conn, domain)` | DELETE | `/api/v1/domain_blocks` | `:empty` | `%{domain: domain}` |

Entity modules to strip in PR 2 (functions + `alias Hunter.Api.HTTPClient` removed; struct/type/docs kept): `Account`, `Application`, `Attachment`, `Client`, `Context`, `Domain`, `Instance`, `List`, `Notification`, `Poll`, `Relationship`, `Report`, `Result`, `Status`, `WebPushSubscription`.

---

# PR 1 — Transport merge (non-breaking)

One deliberate refinement over the spec: the spec's `request!/5` gains an optional sixth `opts` argument (`headers: [{name, value}]`) because `create_status/3` must attach an `Idempotency-Key` header on top of the conn's auth header — there is no other caller-supplied-header case.

Branch off `main`:

```bash
git checkout main && git pull && git checkout -b refactor/transport-merge
```

### Task 1: Conn-aware `Request.request!/6` — failing tests

**Files:**
- Modify: `test/hunter/api/request_test.exs` (full rewrite)

**Interfaces:**
- Produces: the test-defined contract for `Hunter.Api.Request.request!(conn_or_base_url, method, path, to, payload \\ [], opts \\ [])` that Task 2 implements. `conn_or_base_url` is a `%Hunter.Client{}` or a bare base-URL string; `to` is the Transformer atom (or `nil` for raw decoded body); `opts` supports `headers: [{name, value}]` extra request headers. On non-2xx or transport error it raises `Hunter.Error`. It merges `Hunter.Config.req_options()` into every request (that is how the test env injects `plug: {Req.Test, Hunter.ReqStub}` — see `config/config.exs` test section / `test_helper.exs`).

- [ ] **Step 1: Replace `test/hunter/api/request_test.exs` with tests for the new public surface**

The old file tests `process_request_body/1`, `process_request_header/1`, `handle_response/1`, `split_payload/2`, and method-first `request/5` — all of which become private in this PR. The new file covers the same behaviors through `request!/6`, using the app-wide `Hunter.ReqStub` (installed by `Hunter.ReqCase`'s `stub_request/1`) rather than a per-module plug, because `request!/6` reads its Req options from `Hunter.Config.req_options()`:

```elixir
defmodule Hunter.Api.RequestTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Api.Request

  @conn Hunter.Client.new(base_url: "https://mastodon.example", access_token: "123456")

  describe "request!/6 with a %Hunter.Client{}" do
    test "GET joins the path onto base_url, encodes params, sets auth and accept headers" do
      stub_request(fn conn ->
        assert conn.method == "GET"
        assert conn.host == "mastodon.example"
        assert conn.request_path == "/api/v1/timelines/home"
        assert conn.query_string == "limit=1&local=true"
        assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer 123456"]
        assert Plug.Conn.get_req_header(conn, "accept") == ["application/json; charset=utf-8"]
        respond_with(conn, [%{id: "1"}])
      end)

      assert [%Hunter.Status{id: "1"}] =
               Request.request!(@conn, :get, "/api/v1/timelines/home", :statuses,
                 limit: 1,
                 local: true
               )
    end

    test "GET encodes list values as Rails-style repeated keys" do
      stub_request(fn conn ->
        assert conn.query_string == "id%5B%5D=1&id%5B%5D=2"
        respond_with(conn, [])
      end)

      assert [] = Request.request!(@conn, :get, "/api/v1/statuses", :statuses, %{id: [1, 2]})
    end

    test "POST sends a JSON body with the JSON content type" do
      stub_request(fn conn ->
        assert conn.method == "POST"
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/json"]
        assert read_json_body!(conn) == %{"status" => "hi"}
        respond_with_fixture(conn, "status")
      end)

      assert %Hunter.Status{} =
               Request.request!(@conn, :post, "/api/v1/statuses", :status, %{status: "hi"})
    end

    test "empty payload on a write verb sends an empty JSON object" do
      stub_request(fn conn ->
        assert read_json_body!(conn) == %{}
        respond_with_fixture(conn, "status")
      end)

      assert %Hunter.Status{} =
               Request.request!(@conn, :post, "/api/v1/statuses/1/reblog", :status)
    end

    test "extra headers from opts are sent alongside the auth header" do
      stub_request(fn conn ->
        assert Plug.Conn.get_req_header(conn, "idempotency-key") == ["abc123"]
        assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer 123456"]
        respond_with_fixture(conn, "status")
      end)

      assert %Hunter.Status{} =
               Request.request!(@conn, :post, "/api/v1/statuses", :status, %{status: "hi"},
                 headers: [{"idempotency-key", "abc123"}]
               )
    end

    test "to: nil returns the JSON-decoded body without struct transformation" do
      stub_request(fn conn -> respond_with(conn, %{count: 7}) end)

      assert %{"count" => 7} =
               Request.request!(@conn, :get, "/api/v1/notifications/unread_count", nil)
    end

    test "non-2xx responses raise Hunter.Error" do
      stub_request(fn conn -> respond_with(conn, %{error: "Record not found"}, 404) end)

      assert_raise Hunter.Error, fn ->
        Request.request!(@conn, :get, "/api/v1/statuses/0", :status)
      end
    end
  end

  describe "request!/6 with a bare base URL" do
    test "sends no authorization header" do
      stub_request(fn conn ->
        assert conn.request_path == "/api/v1/apps"
        assert Plug.Conn.get_req_header(conn, "authorization") == []
        respond_with_fixture(conn, "application")
      end)

      assert %Hunter.Application{} =
               Request.request!("https://mastodon.example", :post, "/api/v1/apps", :application, %{
                 client_name: "hunter"
               })
    end
  end
end
```

Notes for the implementer:
- `respond_with/2-3`, `respond_with_fixture/2-3`, `read_json_body!/1`, `stub_request/1` come from `Hunter.ReqCase` (`test/support/req_case.ex`).
- Check `test/fixtures/` for the exact fixture names: `status.json` and `application.json` are used above; if a name differs (`ls test/fixtures`), use the existing fixture and adjust the asserted struct fields accordingly.
- The multipart path is intentionally not tested here; `test/hunter/attachment_test.exs` (PR 2: retargeted to `Hunter.upload_media/3`) already covers it end-to-end.

- [ ] **Step 2: Run the new tests to verify they fail**

Run: `mix test test/hunter/api/request_test.exs`
Expected: FAIL — `Request.request!/4`..`/6` undefined or `FunctionClauseError` (the current `request!` expects a method atom as first argument).

- [ ] **Step 3: Do not commit yet** — Task 2 commits the tests together with the implementation so no red commit lands on the branch.

### Task 2: Implement `Request.request!/6`

**Files:**
- Modify: `lib/hunter/api/request.ex`

**Interfaces:**
- Consumes: `Hunter.Api.Transformer.transform/2`, `Hunter.Config.req_options/0`, `Hunter.Error`.
- Produces: `Hunter.Api.Request.request!(conn_or_base_url, method, path, to, payload \\ [], opts \\ [])` — the only public function of the module after Task 4. Tasks 3+ and all of PR 2 call exactly this.

- [ ] **Step 1: Add the conn-aware `request!/6` to `lib/hunter/api/request.ex`**

Add below the `@moduledoc` (and add the aliases). The existing `request/5` stays public for now — `HTTPClient` still calls it until Task 3:

```elixir
defmodule Hunter.Api.Request do
  @moduledoc """
  The single HTTP transport for Hunter.

  `request!/6` joins the endpoint path onto the base URL, sets
  authentication headers from the `Hunter.Client` (none for a bare base
  URL string), performs the request via `Req`, decodes the response
  through `Hunter.Api.Transformer`, and raises `Hunter.Error` on failure.
  """

  alias Hunter.{Api.Transformer, Config}

  @doc """
  Performs a request against the Mastodon API and returns the transformed
  entity.

  ## Parameters

    * `conn_or_base_url` - a `Hunter.Client` (authenticated) or a base URL
      string (unauthenticated, e.g. app registration and OAuth flows)
    * `method` - `:get`, `:post`, `:put`, `:patch` or `:delete`
    * `path` - endpoint path, e.g. `"/api/v1/statuses"`
    * `to` - `Hunter.Api.Transformer` target (e.g. `:status`, `:accounts`,
      `:empty`), or `nil` for the JSON-decoded body untouched
    * `payload` - query params for `:get`/`:delete`; JSON body (map or
      keyword) or `{:form_multipart, parts}` for write verbs
    * `opts` - `headers: [{name, value}]` extra request headers

  Raises `Hunter.Error` on non-2xx responses and transport errors.
  """
  def request!(conn_or_base_url, method, path, to, payload \\ [], opts \\ []) do
    url = url_for(conn_or_base_url, path)
    headers = auth_headers(conn_or_base_url) ++ Keyword.get(opts, :headers, [])

    case request(method, url, payload, headers, Config.req_options()) do
      {:ok, body} -> Transformer.transform(body, to)
      {:error, reason} -> raise Hunter.Error, reason: reason
    end
  end

  defp url_for(%Hunter.Client{base_url: base_url}, path), do: base_url <> path
  defp url_for(base_url, path) when is_binary(base_url), do: base_url <> path

  defp auth_headers(%Hunter.Client{access_token: token}),
    do: [{"authorization", "Bearer #{token}"}]

  defp auth_headers(base_url) when is_binary(base_url), do: []

  # ... existing request/5 and helpers below, unchanged for now ...
end
```

Delete the old `request!/5` (method-first) — nothing calls it (`grep -rn "Request.request!" lib/` before deleting to confirm; as of writing, `HTTPClient` only calls `Request.request/5` and defines its own private `request!`).

- [ ] **Step 2: Run the Task 1 tests**

Run: `mix test test/hunter/api/request_test.exs`
Expected: PASS (all tests).

- [ ] **Step 3: Run the full suite and quality gates**

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`
Expected: all green (`HTTPClient` and entity modules are untouched so far).

- [ ] **Step 4: Commit**

```bash
git add lib/hunter/api/request.ex test/hunter/api/request_test.exs
git commit -m "Add conn-aware Hunter.Api.Request.request!/6

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 3: Rewrite `HTTPClient` endpoints onto `request!/6`

**Files:**
- Modify: `lib/hunter/api/http_client.ex`

**Interfaces:**
- Consumes: `Request.request!/6` from Task 2.
- Produces: every `HTTPClient` endpoint function keeps its exact name/arity/return, with its body now a single `Request.request!` call — these bodies are what PR 2 copies into `hunter.ex` verbatim.

- [ ] **Step 1: Apply the mechanical transformation to every endpoint function**

Current shape → new shape:

```elixir
# before
def followers(conn, id, options) do
  "/api/v1/accounts/#{id}/followers"
  |> process_url(conn)
  |> request!(:accounts, :get, options, conn)
end

# after
def followers(conn, id, options) do
  Request.request!(conn, :get, "/api/v1/accounts/#{id}/followers", :accounts, options)
end
```

The argument mapping from the old private `request!(url, to, method, payload, conn)` pipeline to the new call is: `Request.request!(conn, method, path, to, payload)`. Apply it to every function in the file, using the Endpoint Inventory table as the checklist. Additional mechanical points:

- Private helpers `status_action/3`, `follow_request_action/3`, and `retrieve_timeline/3` stay, rewritten the same way (their callers are unchanged), e.g.:

```elixir
defp status_action(conn, id, action) do
  Request.request!(conn, :post, "/api/v1/statuses/#{id}/#{action}", :status)
end
```

- Functions taking a bare `base_url` instead of `conn` pass it straight through as the first argument (`create_app/5`, `log_in/4`, `log_in_oauth/3`):

```elixir
def create_app(name, redirect_uri, scopes, website, base_url) do
  payload = %{
    client_name: name,
    redirect_uris: redirect_uri,
    scopes: Enum.join(scopes, " "),
    website: website
  }

  %Hunter.Application{} =
    app = Request.request!(base_url, :post, "/api/v1/apps", :application, payload)

  %Hunter.Application{app | scopes: scopes, redirect_uri: redirect_uri}
end
```

```elixir
def log_in(%Hunter.Application{} = app, username, password, base_url) do
  payload = %{
    client_id: app.client_id,
    client_secret: app.client_secret,
    grant_type: "password",
    username: username,
    password: password
  }

  payload =
    case app.scopes do
      scopes when is_list(scopes) and scopes != [] ->
        Map.put(payload, :scope, Enum.join(scopes, " "))

      _ ->
        payload
    end

  response = Request.request!(base_url, :post, "/oauth/token", nil, payload)

  %Hunter.Client{base_url: base_url, access_token: response["access_token"]}
end
```

`log_in_oauth/3` follows the same pattern with its existing payload (grant_type `"authorization_code"`, `code`, and the `redirect_uri: app.redirect_uri || "urn:ietf:wg:oauth:2.0:oob"` fallback with its explanatory comment — keep the comment).

- `create_status/3` uses the `headers:` opt for the idempotency key and keeps its `:scheduled_status` switch:

```elixir
def create_status(conn, status, options) do
  {idempotency_key, options} = Keyword.pop(options, :idempotency_key)
  body = options |> Keyword.put(:status, status) |> Map.new()

  headers =
    case idempotency_key do
      nil -> []
      key -> [{"idempotency-key", key}]
    end

  # scheduling a status returns a ScheduledStatus instead of a Status
  to = if Keyword.has_key?(options, :scheduled_at), do: :scheduled_status, else: :status

  Request.request!(conn, :post, "/api/v1/statuses", to, body, headers: headers)
end
```

(The header name changes from the atom `:"Idempotency-Key"` to the string `"idempotency-key"` — HTTP header names are case-insensitive and Req normalizes to lowercase, so behavior is identical; `test/hunter/status_test.exs` asserts on the lowercased header if it covers this.)

- `upload_media/3` keeps its multipart construction and comment, ending in `Request.request!(conn, :post, "/api/v2/media", :attachment, {:form_multipart, parts})`.
- The post-processed functions keep their pipes, e.g. `unread_count/1` becomes `Request.request!(conn, :get, "/api/v1/notifications/unread_count", nil) |> Map.fetch!("count")` (same for `notification_requests_merged?/1` → `"merged"`, `grouped_unread_count/1` → `"count"`).

- [ ] **Step 2: Delete the now-dead private helpers**

Remove from `http_client.ex`: `request!/5` (private), `get_headers/1`, `process_url/2`, and the `## Helpers` section. Update the top alias to `alias Hunter.Api.Request` only (drop `Transformer` and `Config` — they moved behind `Request.request!/6`).

- [ ] **Step 3: Run the full suite**

Run: `mix compile --warnings-as-errors && mix test`
Expected: PASS — every existing entity/facade test exercises these bodies through the unchanged public API.

- [ ] **Step 4: Format and commit**

```bash
mix format
git add lib/hunter/api/http_client.ex
git commit -m "Route HTTPClient endpoints through Request.request!/6

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 4: Privatize the low-level plumbing and open PR 1

**Files:**
- Modify: `lib/hunter/api/request.ex`

- [ ] **Step 1: Make the old surface private**

In `lib/hunter/api/request.ex`: `grep -rn "Request.request(" lib/ test/` to confirm no external callers remain, then change `def request(...)` to `defp request(...)` and remove the `@doc false` markers plus `def` → `defp` for `handle_response/1`, `split_payload/2`, `process_request_body/1`, `process_request_header/1`. The module's public surface is now exactly `request!/4..6`.

- [ ] **Step 2: Full gate run**

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict && mix dialyzer`
Expected: all green. Dialyzer may need a PLT build on first run (several minutes).

- [ ] **Step 3: Commit and open the PR**

```bash
git add lib/hunter/api/request.ex
git commit -m "Make Request's low-level plumbing private

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
git push -u origin refactor/transport-merge
gh pr create --base main --title "Merge the transport layer into Hunter.Api.Request" --body "..."
```

PR body: summarize PR 1 of the spec (`docs/superpowers/specs/2026-07-08-flatten-facade-design.md`): non-breaking; `Request` absorbs `HTTPClient`'s conn/URL/transform plumbing behind `request!/6`; `HTTPClient` endpoints are now one-liners; sets up the breaking flatten PR. End with the 🤖 attribution line.

---

# PR 2 — The breaking flatten

Branch off PR 1's branch (stacked):

```bash
git checkout refactor/transport-merge && git checkout -b refactor/flatten-facade
```

(After PR 1 squash-merges, rebase with `git rebase --onto main refactor/transport-merge refactor/flatten-facade`.)

**The per-domain recipe.** Tasks 5–11 all follow the same five-step cycle over a group of functions; each task lists its group's specifics. The recipe:

1. **Retarget the domain's test file(s)** to call `Hunter.*` instead of the entity module: update the `alias`, replace `Account.followers(...)` → `Hunter.followers(...)` etc. Function names are identical on the facade except the two noted in Task 6. Struct pattern-matches (`%Account{...}`) keep working — keep the struct aliases.
2. **Run that test file** — it must PASS *before* any lib change (the facade already delegates). This proves the retarget is faithful.
3. **Flatten the facade functions**: in `lib/hunter.ex`, replace each `defdelegate name(args), to: Hunter.X` with `def name(args) do ... end`, where the body is copied verbatim from the current `lib/hunter/api/http_client.ex` function of the same name (after PR 1 these are single `Request.request!` calls; the Endpoint Inventory table is the cross-check). Where the entity module's function had logic of its own (each task lists these), that logic comes along too. Keep the existing `@doc`/`@spec` in `hunter.ex`; where the entity module's `@doc` for the same function has sections `hunter.ex` lacks (Options, Examples, Notes), copy those sections over verbatim before deleting the entity function.
4. **Strip the entity module(s)**: delete the endpoint functions and the `alias Hunter.Api.HTTPClient` (and now-unused aliases like `Config`); keep `@moduledoc` (minus any "main functions for working with X" phrasing — it's now just the entity), `@type t`, `@derive`, `defstruct`. Delete the corresponding functions from `http_client.ex` at the same time (they are dead once `hunter.ex` stops delegating).
5. **Run `mix compile --warnings-as-errors && mix test`, `mix format`, commit.**

One-time setup for Task 5: add `alias Hunter.{Api.Request, Config}` after `@hunter_version` in `lib/hunter.ex`.

### Task 5: Flatten client, auth, and apps

**Files:**
- Modify: `lib/hunter.ex`, `lib/hunter/client.ex`, `lib/hunter/application.ex`, `lib/hunter/api/http_client.ex`
- Test: `test/hunter/client_test.exs`, `test/hunter/application_test.exs`

**Interfaces:**
- Consumes: `Request.request!/6`.
- Produces: `Hunter.new/1`, `Hunter.user_agent/0`, `Hunter.log_in/4`, `Hunter.log_in_oauth/3`, `Hunter.create_app/5`, `Hunter.load_credentials/1` as real implementations; `Hunter.Client` and `Hunter.Application` as pure structs.

Follow the per-domain recipe. Domain specifics:

- [ ] **Step 1: Retarget `client_test.exs` and `application_test.exs` to `Hunter.*`; run them — PASS before lib changes**

Run: `mix test test/hunter/client_test.exs test/hunter/application_test.exs`

- [ ] **Step 2: Flatten in `lib/hunter.ex`**

`new/1` and `user_agent/0` become local (note `user_agent` now calls `version/0` directly):

```elixir
@spec new(Keyword.t()) :: Hunter.Client.t()
def new(options \\ []), do: struct(Hunter.Client, options)

@spec user_agent() :: String.t()
def user_agent, do: "Hunter.Elixir/#{version()}"
```

`log_in/4` and `log_in_oauth/3` merge the `Hunter.Client` wrapper (the `base_url || Config.api_base_url()` fallback) with the `HTTPClient` body from PR 1 Task 3:

```elixir
def log_in(%Hunter.Application{} = app, username, password, base_url \\ "https://mastodon.social") do
  base_url = base_url || Config.api_base_url()

  payload = %{
    client_id: app.client_id,
    client_secret: app.client_secret,
    grant_type: "password",
    username: username,
    password: password
  }

  payload =
    case app.scopes do
      scopes when is_list(scopes) and scopes != [] ->
        Map.put(payload, :scope, Enum.join(scopes, " "))

      _ ->
        payload
    end

  response = Request.request!(base_url, :post, "/oauth/token", nil, payload)

  %Hunter.Client{base_url: base_url, access_token: response["access_token"]}
end
```

`log_in_oauth/3` follows the same shape with its `base_url \\ "https://mastodon.social"` default and `Config.api_base_url()` fallback, and the payload from `http_client.ex` (grant_type `"authorization_code"`, `code: oauth_code`, `redirect_uri: app.redirect_uri || "urn:ietf:wg:oauth:2.0:oob"` — keep the Doorkeeper comment).

`create_app/5` merges `Hunter.Application.create_app`'s `save?`/`api_base_url` handling with `HTTPClient.create_app`'s request:

```elixir
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

  app = %Hunter.Application{app | scopes: scopes, redirect_uri: redirect_uris}

  if save?, do: save_credentials(client_name, app)

  app
end
```

`load_credentials/1` and the private `save_credentials/2` move verbatim from `lib/hunter/application.ex` (they are file I/O, not HTTP).

- [ ] **Step 3: Strip `Hunter.Client` and `Hunter.Application` to structs; delete `create_app`, `log_in`, `log_in_oauth` from `http_client.ex`**

- [ ] **Step 4: Run gates and commit**

```bash
mix compile --warnings-as-errors && mix test && mix format
git add lib/hunter.ex lib/hunter/client.ex lib/hunter/application.ex lib/hunter/api/http_client.ex test/hunter/client_test.exs test/hunter/application_test.exs
git commit -m "Flatten client, auth, and app registration into Hunter

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 6: Flatten accounts and relationships

**Files:**
- Modify: `lib/hunter.ex`, `lib/hunter/account.ex`, `lib/hunter/relationship.ex`, `lib/hunter/api/http_client.ex`
- Test: `test/hunter/account_test.exs`, `test/hunter/relationship_test.exs`

Follow the per-domain recipe for: `verify_credentials`, `update_credentials`, `account`, `followers`, `following`, `search_account`, `blocks`, `follow_requests`, `mutes`, `accept_follow_request`, `reject_follow_request`, `reblogged_by`, `favourited_by`, `relationships`, `follow`, `unfollow`, `block`, `unblock`, `mute`, `unmute`.

Domain specifics:

- `search_account/2` carries `Hunter.Account`'s opts-building:

```elixir
def search_account(conn, options) do
  opts = %{
    q: Keyword.fetch!(options, :q),
    limit: Keyword.get(options, :limit, 40)
  }

  Request.request!(conn, :get, "/api/v1/accounts/search", :accounts, opts)
end
```

- `accept_follow_request/2` and `reject_follow_request/2` are the only facade functions whose entity/HTTPClient counterpart has a different name (`follow_request_action/3`). Inline the action:

```elixir
def accept_follow_request(conn, id) do
  Request.request!(conn, :post, "/api/v1/follow_requests/#{id}/authorize", :relationship)
end

def reject_follow_request(conn, id) do
  Request.request!(conn, :post, "/api/v1/follow_requests/#{id}/reject", :relationship)
end
```

- The six relationship actions (`follow` … `unmute`) are uniform POSTs per the Endpoint Inventory table.
- Note `notification_test.exs` also aliases `Account` (for struct matches only) — leave it; it is retargeted in Task 10.

Commit message: `Flatten accounts and relationships into Hunter`.

### Task 7: Flatten statuses, polls, timelines, search, and context

**Files:**
- Modify: `lib/hunter.ex`, `lib/hunter/status.ex`, `lib/hunter/poll.ex`, `lib/hunter/result.ex`, `lib/hunter/context.ex`, `lib/hunter/api/http_client.ex`
- Test: `test/hunter/status_test.exs`, `test/hunter/poll_test.exs`, `test/hunter/result_test.exs`, `test/hunter/context_test.exs`

Follow the per-domain recipe for: `create_status`, `status`, `statuses_by_ids`, `edit_status`, `status_history`, `status_source`, `destroy_status`, `bookmark`, `unbookmark`, `pin`, `unpin`, `mute_conversation`, `unmute_conversation`, `bookmarks`, `translate_status`, `reblog`, `unreblog`, `favourite`, `unfavourite`, `favourites`, `statuses`, `home_timeline`, `public_timeline`, `hashtag_timeline`, `list_timeline`, `poll`, `vote`, `search`, `status_context`.

Domain specifics:

- `create_status/3` moves with its idempotency/scheduled logic exactly as written in PR 1 Task 3.
- The private helpers `status_action/3` and `retrieve_timeline/3` move from `http_client.ex` into `hunter.ex` as private functions (place them after the last function that uses them); the six status actions and four timelines keep calling them.
- `search/3` keeps `Hunter.Result.search`'s query merge: `options = options |> Keyword.merge(q: query) |> Map.new()` then `Request.request!(conn, :get, "/api/v2/search", :result, options)`.

Commit message: `Flatten statuses, polls, timelines, search, and context into Hunter`.

### Task 8: Flatten media attachments

**Files:**
- Modify: `lib/hunter.ex`, `lib/hunter/attachment.ex`, `lib/hunter/api/http_client.ex`
- Test: `test/hunter/attachment_test.exs`

Recipe over: `upload_media`, `media_attachment`, `update_media`, `delete_media`. `upload_media/3` moves with its multipart parts construction and the byte-streaming comment intact.

Commit message: `Flatten media attachments into Hunter`.

### Task 9: Flatten lists

**Files:**
- Modify: `lib/hunter.ex`, `lib/hunter/list.ex`, `lib/hunter/api/http_client.ex`
- Test: `test/hunter/list_test.exs`

Recipe over: `lists`, `list`, `create_list`, `update_list`, `destroy_list`, `list_accounts`, `add_accounts_to_list`, `remove_accounts_from_list`, `account_lists`. All uniform per the table (`create_list` builds `options |> Keyword.put(:title, title) |> Map.new()`).

Commit message: `Flatten lists into Hunter`.

### Task 10: Flatten notifications and push subscriptions

**Files:**
- Modify: `lib/hunter.ex`, `lib/hunter/notification.ex`, `lib/hunter/web_push_subscription.ex`, `lib/hunter/api/http_client.ex`
- Test: `test/hunter/notification_test.exs`, `test/hunter/web_push_subscription_test.exs`

Recipe over the 19 notification functions and 4 push functions in the table. The three post-processed functions keep their pipes:

```elixir
def unread_count(conn) do
  Request.request!(conn, :get, "/api/v1/notifications/unread_count", nil)
  |> Map.fetch!("count")
end
```

(same shape for `notification_requests_merged?/1` with `"merged"` and `grouped_unread_count/1` with `"count"` against `/api/v2/notifications/unread_count`).

Commit message: `Flatten notifications and push subscriptions into Hunter`.

### Task 11: Flatten instance, domains, reports — delete `HTTPClient`

**Files:**
- Modify: `lib/hunter.ex`, `lib/hunter/instance.ex`, `lib/hunter/domain.ex`, `lib/hunter/report.ex`
- Delete: `lib/hunter/api/http_client.ex`
- Test: `test/hunter/instance_test.exs`, `test/hunter/domain_test.exs`, `test/hunter/report_test.exs`

Recipe over: `instance_info`, `blocked_domains`, `block_domain`, `unblock_domain`, `report`. `report/4` moves with its payload map; `blocked_domains` uses transform `nil` (the API returns bare strings).

- [ ] **Step: after stripping these three entities, `http_client.ex` must be empty of functions — delete the file, then verify nothing references it:**

Run: `grep -rn "HTTPClient" lib/ test/ README.md`
Expected: no matches.

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted`
Expected: all green.

Commit message: `Flatten instance, domains, reports; delete Hunter.Api.HTTPClient`.

### Task 12: Retarget the integration suite

**Files:**
- Modify: `test/integration/mastodon_test.exs` (and `test/hunter/integration_case_test.exs` / `test/support/integration_case.ex` if they reference entity functions)

- [ ] **Step 1: Replace entity calls with facade calls**

Drop the `alias Hunter.{Account, Attachment, ...}` for *function* calls — every `Account.foo(...)`, `Status.foo(...)`, `Hunter.List.foo(...)`, `Hunter.Poll.foo(...)`, `Hunter.WebPushSubscription.foo(...)` call becomes `Hunter.foo(...)`. Keep aliases needed for struct pattern-matches (`%Account{id: ^id2}`).

- [ ] **Step 2: Compile-check the excluded suite**

Integration tests are tagged/excluded by default, but they still must compile:

Run: `mix compile --warnings-as-errors && mix test --only integration --dry-run || mix test`
(If `--dry-run` is unsupported, `mix test` alone recompiles the file and proves it compiles; actually running the integration suite requires live credentials — do not attempt it.)

- [ ] **Step 3: Commit**

```bash
git add test/
git commit -m "Point the integration suite at the Hunter facade

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 13: CHANGELOG, version 0.7.0, README — open PR 2

**Files:**
- Modify: `CHANGELOG.md`, `mix.exs`, `README.md`

- [ ] **Step 1: CHANGELOG entry**

Add a `## 0.7.0` section: a **Breaking changes** block stating that all endpoint functions on entity modules were removed and live only on `Hunter`, with a migration table generated from the Endpoint Inventory — one row per removed entity module mapping old → new (e.g. `Hunter.Account.followers/3` → `Hunter.followers/3`; `Hunter.Client.new/1` → `Hunter.new/1`; `Hunter.Application.create_app/5` → `Hunter.create_app/5`; `Hunter.Client.log_in/4` → `Hunter.log_in/4`; …). Note that entity structs are unchanged and that `Hunter.Api.HTTPClient` (internal) was replaced by `Hunter.Api.Request.request!/6`.

- [ ] **Step 2: Bump `@version "0.6.0"` → `"0.7.0"` in `mix.exs`**

- [ ] **Step 3: Audit `README.md`**

`grep -n "Hunter\." README.md` — rewrite any entity-module call (e.g. `Hunter.Application.load_credentials("hunter")` at line ~54 → `Hunter.load_credentials("hunter")`).

- [ ] **Step 4: Docs build and final gates**

Run: `mix docs && mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict && mix dialyzer`
Expected: all green; `mix docs` emits no warnings about broken references (entity-module function references in remaining docs would show up here).

- [ ] **Step 5: Commit and open the stacked PR**

```bash
git add CHANGELOG.md mix.exs README.md
git commit -m "Release prep: 0.7.0 breaking-changes changelog and README update

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
git push -u origin refactor/flatten-facade
gh pr create --base refactor/transport-merge --title "Flatten the facade: all endpoints live on Hunter" --body "..."
```

PR body: link the spec, state the breaking change and migration table location (CHANGELOG), note the stacked base and that it re-bases onto `main` after PR 1 squash-merges. End with the 🤖 attribution line.
