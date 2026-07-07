# Query Params (#74) + API-Drift Cleanup (#106) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** GET/DELETE options travel as real query-string parameters (fixes #74), then the API surface modern Mastodon removed is cleaned up (closes #106) — two stacked PRs.

**Architecture:** PR A (`query-params`, exists off `main` with the spec committed) adds a pure `split_payload/2` routing function to `Hunter.Api.Request` so verb decides body-vs-params once, for every endpoint; `relationships/2` drops its hand-rolled query string. PR B (`api-drift`, off `query-params`) re-shapes `Result.hashtags` to v2 (`[%Hunter.Tag{}]`) and removes `follow_by_uri` and `reports/1` end to end.

**Tech Stack:** Elixir/ExUnit, HTTPoison `params:` option, Mox, the live-Mastodon integration stack from `docker-compose.ci.yml`.

**Spec:** `docs/superpowers/specs/2026-07-07-query-params-and-api-drift-design.md`

## Global Constraints

- Public signatures of `Request.request/5` and `request!/5` unchanged; POST/PATCH body behavior byte-identical.
- All breaking changes (hashtags shape, removed functions) documented in CHANGELOG.md under Unreleased (0.6.0).
- Every commit passes `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`; Task 6 (behaviour change) also runs `mix dialyzer`.
- Integration verification runs against the local stack: `./scripts/ci/setup_mastodon.sh` then `bash -c 'source scripts/ci/.env.hunter && mix test --only integration'`. If the stack was torn down, the script re-provisions from scratch (needs Docker running).
- Commit messages end with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`; PR bodies end with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
- PR A body says `Fixes #74`; PR B body says `Closes #106`.

---

# PR A: query parameters (branch `query-params`, base `main`)

The branch already exists with the spec committed (`bfa56d9`). Work on it directly.

### Task 1: `split_payload/2` in `Hunter.Api.Request` (TDD)

**Files:**
- Modify: `lib/hunter/api/request.ex`
- Test: `test/hunter/api/request_test.exs` (append a describe block)

**Interfaces:**
- Produces: `Hunter.Api.Request.split_payload(method :: atom, data) :: {body :: binary | tuple, params :: [{String.t(), String.t()}]}` — public, `@doc false`, like the module's other helpers. Task 2 and every GET/DELETE endpoint rely on it via `request/5`.

- [ ] **Step 1: Append failing tests to `test/hunter/api/request_test.exs`** (inside the module, after the `handle_response/1` describe):

```elixir
  describe "split_payload/2" do
    test "GET routes data to query params with an empty body" do
      assert Request.split_payload(:get, limit: 1, local: true) ==
               {"", [{"limit", "1"}, {"local", "true"}]}
    end

    test "DELETE routes data to query params" do
      assert Request.split_payload(:delete, %{domain: "spam.example"}) ==
               {"", [{"domain", "spam.example"}]}
    end

    test "list values encode as Rails-style repeated keys" do
      assert Request.split_payload(:get, %{id: [1, 2]}) ==
               {"", [{"id[]", "1"}, {"id[]", "2"}]}
    end

    test "empty data produces no params" do
      assert Request.split_payload(:get, []) == {"", []}
      assert Request.split_payload(:get, %{}) == {"", []}
    end

    test "write verbs keep the JSON body and produce no params" do
      assert Request.split_payload(:post, %{status: "hi"}) == {~s({"status":"hi"}), []}
      assert Request.split_payload(:patch, []) == {"{}", []}
    end

    test "multipart payloads pass through untouched on write verbs" do
      payload = {:multipart, [{:file, "/tmp/image.png"}]}
      assert Request.split_payload(:post, payload) == {payload, []}
    end
  end
```

- [ ] **Step 2: Run to verify failure**

Run: `mix test test/hunter/api/request_test.exs`
Expected: FAIL — `Request.split_payload/2` is undefined; the 9 existing tests still pass.

- [ ] **Step 3: Implement in `lib/hunter/api/request.ex`**

Replace the `request/5` body and add the new functions (the rest of the module — `request!/5`, `handle_response/1`, `process_request_body/1`, `process_request_header/1` — stays exactly as-is):

```elixir
  def request(http_method, url, data \\ [], headers \\ [], options \\ []) do
    {body, params} = split_payload(http_method, data)
    headers = process_request_header(headers)
    options = attach_params(options, params)

    http_method
    |> HTTPoison.request(url, body, headers, options)
    |> handle_response()
  end
```

New public helper (place after `handle_response/1` clauses):

```elixir
  @doc false
  def split_payload(method, data) when method in [:get, :delete] do
    {"", encode_params(data)}
  end

  def split_payload(_method, data), do: {process_request_body(data), []}
```

New private helpers (place at the bottom of the module):

```elixir
  defp attach_params(options, []), do: options
  defp attach_params(options, params), do: Keyword.put(options, :params, params)

  defp encode_params(data) do
    Enum.flat_map(data, fn
      {key, values} when is_list(values) -> Enum.map(values, &{"#{key}[]", to_string(&1)})
      {key, value} -> [{to_string(key), to_string(value)}]
    end)
  end
```

Notes: values are stringified because hackney's query-string encoder requires binaries (integers/booleans would crash); `attach_params/2` leaves `options` untouched when there are no params so HTTPoison appends no bare `?`.

- [ ] **Step 4: Run the full gate**

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`
Expected: all green — 4 doctests, 79 tests (73 + 6 new), 0 failures.

- [ ] **Step 5: Commit**

```bash
git add lib/hunter/api/request.ex test/hunter/api/request_test.exs
git commit -m "route GET/DELETE options to query params instead of JSON bodies

Fixes the transport for ~16 endpoints whose options only worked because
Rails happens to parse JSON bodies on GET/DELETE (#74).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 2: `relationships/2` drops its hand-rolled query string

**Files:**
- Modify: `lib/hunter/api/http_client.ex:104-110`

**Interfaces:**
- Consumes: `split_payload/2`'s array encoding from Task 1 (`%{id: ids}` → `id[]=…&id[]=…`).

- [ ] **Step 1: Replace the function**

Current code (lib/hunter/api/http_client.ex:104-110):

```elixir
  def relationships(conn, ids) do
    ids_array = Enum.map(ids, fn id -> "id[]=#{id}&" end)

    "/api/v1/accounts/relationships?#{ids_array}"
    |> process_url(conn)
    |> request!(:relationships, :get, [], conn)
  end
```

New code:

```elixir
  def relationships(conn, ids) do
    "/api/v1/accounts/relationships"
    |> process_url(conn)
    |> request!(:relationships, :get, %{id: ids}, conn)
  end
```

- [ ] **Step 2: Full gate**

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`
Expected: green (the Mox-based relationship tests don't exercise HTTPClient; live verification is Task 3).

- [ ] **Step 3: Commit**

```bash
git add lib/hunter/api/http_client.ex
git commit -m "build relationships query via the params mechanism

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 3: integration proof that params reach the server

**Files:**
- Modify: `test/integration/mastodon_test.exs` (append one test before the final `end`)

**Interfaces:**
- Consumes: `Hunter.IntegrationCase` (`conn` context, `eventually/2`); `Status.statuses/3` (converts options via `Map.new/1`, so keyword options are fine).

- [ ] **Step 1: Append the test**

```elixir
  test "query parameters take effect server-side", %{conn: conn} do
    %Account{id: account_id} = Account.verify_credentials(conn)

    %Status{id: id1} = Status.create_status(conn, "pagination one #hunterci")
    %Status{id: id2} = Status.create_status(conn, "pagination two #hunterci")

    eventually(fn ->
      assert [%Status{}] = Status.statuses(conn, account_id, limit: 1)
    end)

    older = Status.statuses(conn, account_id, max_id: id2)
    refute Enum.any?(older, &(&1.id == id2))
    assert Enum.any?(older, &(&1.id == id1))

    Status.destroy_status(conn, id1)
    Status.destroy_status(conn, id2)
  end
```

(`limit: 1` must cap the response at exactly one status — the account has at least two; `max_id: id2` must exclude the anchor and include the older status. Under the old body-transport these still passed via the Rails quirk; the test pins the behavior so the transport can never silently regress to "params ignored".)

- [ ] **Step 2: Run the integration suite against the local stack**

Run: `./scripts/ci/setup_mastodon.sh && bash -c 'source scripts/ci/.env.hunter && mix test --only integration'`
Expected: 8 tests, 0 failures. (The setup script is idempotent; if the stack is already up it just re-mints tokens.)

- [ ] **Step 3: Unit suite still green + format/credo**

Run: `mix test && mix format --check-formatted && mix credo --strict`
Expected: green, integration excluded.

- [ ] **Step 4: Commit**

```bash
git add test/integration/mastodon_test.exs
git commit -m "assert query params take effect server-side

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 4: open PR A

- [ ] **Step 1: Push and create the PR**

```bash
git push -u origin query-params
gh pr create --base main --title "Send GET/DELETE options as query parameters" --body "$(cat <<'EOF'
Fixes #74.

Options for GET/DELETE requests were JSON-encoded into the request body; they only appeared to work because Rails parses JSON bodies on any verb — proxies and CDNs routinely drop them. Now:

- `Request.split_payload/2` routes data by verb: GET/DELETE → HTTPoison `params:` (query string), write verbs → JSON body, byte-identical to before
- Array values encode Rails-style (`id[]=1&id[]=2`); `relationships/2` drops its hand-rolled query string and uses the same path
- Unit tests cover the routing table; a new integration test asserts `limit`/`max_id` actually take effect against a real Mastodon server

PR 1 of 2 — the API-drift cleanup (#106) stacks on this because `/api/v2/search` needs `q` as a real query param.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 2: Watch checks**

Run: `gh pr checks --watch`
Expected: all 5 jobs green (test ×2, lint, dialyzer, integration). On integration failure, `gh run view --log-failed` plus the workflow's Mastodon-log dump step; fix, push, re-watch.

---

# PR B: API-drift cleanup (branch `api-drift`, base `query-params`)

```bash
git checkout query-params && git checkout -b api-drift
```

### Task 5: `Result.hashtags` decodes v2 objects as `Hunter.Tag` structs (TDD)

**Files:**
- Modify: `test/fixtures/result.json`, `test/hunter/api/transformer_test.exs`, `lib/hunter/api/transformer.ex`, `lib/hunter/result.ex`, `test/hunter/result_test.exs`

- [ ] **Step 1: Update the fixture** — in `test/fixtures/result.json`, replace `"hashtags": ["elixir"]` with the v2 object shape:

```json
  "hashtags": [
    { "name": "elixir", "url": "https://mastodon.example/tags/elixir" }
  ]
```

- [ ] **Step 2: Update the transformer test** — in `test/hunter/api/transformer_test.exs`, replace the result test:

```elixir
  test "decodes a search result with nested accounts, statuses, and hashtags" do
    result = transform("result", :result)

    assert %Hunter.Result{} = result
    assert [%Hunter.Account{username: "milmazz"}] = result.accounts
    assert [%Hunter.Status{visibility: "public"}] = result.statuses
    assert [%Hunter.Tag{name: "elixir", url: "https://mastodon.example/tags/elixir"}] =
             result.hashtags
  end
```

- [ ] **Step 3: Run to verify failure**

Run: `mix test test/hunter/api/transformer_test.exs`
Expected: FAIL — hashtags decode as plain maps, not `%Hunter.Tag{}`.

- [ ] **Step 4: Fix the transformer** — in `lib/hunter/api/transformer.ex`, the `:result` clause gains hashtags:

```elixir
  def transform(body, :result) do
    Poison.decode!(
      body,
      as: %Hunter.Result{
        accounts: [%Hunter.Account{}],
        statuses: [status_nested_struct()],
        hashtags: [%Hunter.Tag{}]
      }
    )
  end
```

- [ ] **Step 5: Update `lib/hunter/result.ex`** — the typespec (lines 14-18) becomes:

```elixir
  @type t :: %__MODULE__{
          accounts: [Hunter.Account.t()],
          statuses: [Hunter.Status.t()],
          hashtags: [Hunter.Tag.t()]
        }
```

Also update the `## Fields` moduledoc line for `hashtags` to say "list of matched `Hunter.Tag`" (matching the module's existing doc style).

- [ ] **Step 6: Update the Mox test** — in `test/hunter/result_test.exs`, the expectation's return value becomes realistic:

```elixir
    expect(Hunter.ApiMock, :search, fn %Hunter.Client{}, "elixir", [] ->
      %Result{accounts: [], statuses: [], hashtags: [%Hunter.Tag{name: "elixir"}]}
    end)

    assert %Result{hashtags: [%Hunter.Tag{name: "elixir"}]} = Result.search(@conn, "elixir")
```

- [ ] **Step 7: Full gate and commit**

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`
Expected: green.

```bash
git add test/fixtures/result.json test/hunter/api/transformer_test.exs lib/hunter/api/transformer.ex lib/hunter/result.ex test/hunter/result_test.exs
git commit -m "decode v2 search hashtags as Hunter.Tag structs

BREAKING: Result.hashtags was [String.t()], now [Hunter.Tag.t()] —
matching what /api/v2/search actually returns.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 6: remove `follow_by_uri` and `reports/1`

**Files:**
- Modify: `lib/hunter.ex` (two blocks), `lib/hunter/account.ex:190-205`, `lib/hunter/report.ex:24-35`, `lib/hunter/api.ex` (two callback blocks), `lib/hunter/api/http_client.ex` (two functions), `lib/hunter/api/transformer.ex` (`:reports` clause), `test/hunter/account_test.exs`, `test/hunter/report_test.exs`, `test/hunter/api/transformer_test.exs`

Each deletion removes the function together with its `@doc` block and `@spec`/`@callback`:

- [ ] **Step 1: `lib/hunter.ex`** — delete the `follow_by_uri` block (the `@doc "Follow a remote user…"` through `defdelegate follow_by_uri(conn, uri), to: Hunter.Account`, around lines 88-98) and the `reports` block (`@doc "Retrieve a user's reports…"` through `defdelegate reports(conn), to: Hunter.Report`, around lines 673-682).

- [ ] **Step 2: `lib/hunter/account.ex`** — delete the `follow_by_uri` block (doc + spec + def, around lines 190-205).

- [ ] **Step 3: `lib/hunter/report.ex`** — delete the `reports/1` block (doc + spec + def, around lines 24-35). `report/4` stays.

- [ ] **Step 4: `lib/hunter/api.ex`** — delete the `@callback follow_by_uri(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Account.t()` with its doc (around lines 85-94) and `@callback reports(conn :: Hunter.Client.t()) :: [Hunter.Report.t()]` with its doc (around lines 616-624).

- [ ] **Step 5: `lib/hunter/api/http_client.ex`** — delete `follow_by_uri/2` (lines 40-44, targets the removed `/api/v1/follows`) and `reports/1` (lines 272-276, targets the removed `GET /api/v1/reports`).

- [ ] **Step 6: `lib/hunter/api/transformer.ex`** — delete the `:reports` clause (`def transform(body, :reports), do: Poison.decode!(body, as: [%Hunter.Report{}])`). The `:report` clause stays (used by `report/4`).

- [ ] **Step 7: Tests** — delete the `"following a remote user"` test from `test/hunter/account_test.exs`, the `"returns authenticated user's reports"` test from `test/hunter/report_test.exs`, and the `"decodes a list of reports"` test from `test/hunter/api/transformer_test.exs`.

- [ ] **Step 8: Full gate including dialyzer**

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict && mix dialyzer`
Expected: all green — compile with warnings-as-errors proves no dangling references; dialyzer revalidates the shrunk behaviour. (Mox mocks are generated from the behaviour, so removed callbacks disappear automatically.)

- [ ] **Step 9: Commit**

```bash
git add lib test
git commit -m "remove follow_by_uri and reports listing

BREAKING: POST /api/v1/follows and GET /api/v1/reports were removed
from Mastodon (4.0 and earlier); the functions could only return 404.
Filing reports via report/4 is unaffected.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 7: CHANGELOG + live v2-search integration test

**Files:**
- Modify: `CHANGELOG.md`, `test/integration/mastodon_test.exs`

- [ ] **Step 1: CHANGELOG** — under the existing `## Unreleased` → breaking-changes section (added during the CI work), append:

```markdown
* `Hunter.Result.hashtags` is now a list of `Hunter.Tag` structs (the
  `/api/v2/search` shape) instead of strings.
* Removed `Hunter.follow_by_uri/2` / `Hunter.Account.follow_by_uri/2`:
  Mastodon 4.0 removed `POST /api/v1/follows`. Search for the account and
  use `Hunter.follow/2` instead.
* Removed `Hunter.reports/1` / `Hunter.Report.reports/1`: Mastodon removed
  `GET /api/v1/reports`. Filing reports via `Hunter.report/4` still works.
```

- [ ] **Step 2: Integration test** — in `test/integration/mastodon_test.exs`, add `Result` to the alias line (`alias Hunter.{Account, Attachment, Instance, Notification, Relationship, Result, Status}`) and append:

```elixir
  test "searches via /api/v2/search returning v2 shapes", %{conn: conn} do
    %Status{id: id} = Status.create_status(conn, "tagged search probe #hunterci")

    eventually(fn ->
      result = Result.search(conn, "hunterci")
      assert Enum.any?(result.hashtags, &match?(%Hunter.Tag{name: "hunterci"}, &1))
    end)

    people = Result.search(conn, "kadaba")
    assert Enum.any?(people.accounts, &(&1.username == "kadaba"))

    Status.destroy_status(conn, id)
  end
```

(Status full-text search needs Elasticsearch, which the CI stack deliberately runs without (`ES_ENABLED=false`) — so the test asserts the hashtag and account facets, which work without ES, and does not assert on `result.statuses`.)

- [ ] **Step 3: Run integration + unit suites**

Run: `bash -c 'source scripts/ci/.env.hunter && mix test --only integration'` then `mix test && mix format --check-formatted && mix credo --strict`
Expected: 9 integration tests, 0 failures; unit suite green.

- [ ] **Step 4: Commit**

```bash
git add CHANGELOG.md test/integration/mastodon_test.exs
git commit -m "document 0.6.0 breaking changes and cover v2 search live

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 8: open PR B, correct and close #106

- [ ] **Step 1: Push and create the PR**

```bash
git push -u origin api-drift
gh pr create --base query-params --title "API-drift cleanup: v2 search shape, drop removed endpoints" --body "$(cat <<'EOF'
Closes #106. PR 2 of 2, stacked on #<PR A number>.

- `Result.hashtags` now decodes as `[Hunter.Tag.t()]` — the actual `/api/v2/search` shape (breaking, 0.6.0)
- Removed `follow_by_uri` (`POST /api/v1/follows` was removed in Mastodon 4.0) and `reports/1` (`GET /api/v1/reports` removed); `report/4` filing is unaffected (breaking, 0.6.0)
- New live integration test covers v2 search (hashtag + account facets; status facet needs Elasticsearch, which the CI stack intentionally omits)

Note: #106's claim that `Result.search` targets `/api/v1/search` was stale — the code already used v2. The real gaps were the query-param transport (fixed by the base PR) and the hashtag shape (fixed here).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Replace `#<PR A number>` with the number from Task 4.

- [ ] **Step 2: Comment the correction on #106**

```bash
gh issue comment 106 --body "Correction while implementing: \`Result.search\` already targets \`/api/v2/search\` — the first bullet of this issue was stale. The real remaining problems were (a) \`q\` traveling in a JSON GET body instead of the query string (fixed by the query-params PR) and (b) \`hashtags\` decoding as v1-style strings (fixed by the PR that closes this). \`follow_by_uri\` and \`GET /api/v1/reports\` removals were accurate."
```

- [ ] **Step 3: Watch checks**

Run: `gh pr checks --watch`
Expected: all 5 jobs green.

---

## Merge order

PR A → `main` first, then PR B retargets and merges. If PR A is squash-merged, PR B needs the same sync applied to the previous stack (merge `origin/main` into `api-drift` with ours-preference after verifying tree identity) — or merge PR A with a merge commit to avoid it.
