# Auth Fixes Implementation Plan (#100 + #101)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `log_in/4` requests the app's registered scopes so tokens can write (#100), and `Hunter.Client.bearer_token` becomes `access_token` (#101) — one branch, one PR, 0.6.0.

**Architecture:** Rename first (Task 2) so all later code uses the new field. Then `Hunter.Application` grows a `scopes` field that `create_app` fills with the *requested* scopes (Task 3), and `log_in` joins them into the password-grant `scope` parameter, omitting it when `scopes` is nil/empty so stale saved credentials keep today's behavior (Task 4). The regression proof is a live integration test running the README auth flow end-to-end (Task 5).

**Tech Stack:** Elixir/ExUnit, Mox, Poison persistence, the docker-compose Mastodon stack (`tootctl` password reset for a known login).

**Spec:** `docs/superpowers/specs/2026-07-07-auth-fixes-design.md`

## Global Constraints

- Branch `auth-fixes` off `main` (exists, spec committed at e18acf1). Single PR, base `main`.
- Hard rename: after Task 2, `git grep -n "bearer_token" -- lib test README.md` returns nothing (CHANGELOG history may keep old mentions; none exist today).
- `scope` parameter omitted from the token payload when `Application.scopes` is `nil` or `[]` (old saved credentials keep current behavior).
- Every commit passes `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`; run `mix dialyzer` once in Task 6 before pushing (struct/type changes).
- Integration verification: `./scripts/ci/setup_mastodon.sh` then `bash -c 'source scripts/ci/.env.hunter && mix test --only integration'`.
- Commit messages end with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`; PR body ends with `🤖 Generated with [Claude Code](https://claude.com/claude-code)` and says `Fixes #100. Closes #101.`

---

### Task 1: restore the CHANGELOG entry lost in the #109 rebase-merge

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Add the Bug fixes block** — under `## Unreleased`, after the `* Breaking changes` block (currently ending with the `reports/1` bullet around line 14), insert:

```markdown

  * Bug fixes
    - GET/DELETE request options now travel as query-string parameters instead
      of JSON request bodies, which proxies routinely drop ([#74])
```

and at the bottom of the file add the link reference (match the file's existing reference style; if none exists, plain `[#74]: https://github.com/milmazz/hunter/issues/74` on its own line at the end):

```markdown
[#74]: https://github.com/milmazz/hunter/issues/74
```

- [ ] **Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "restore #74 changelog entry dropped in the #109 rebase-merge

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 2: #101 hard rename `bearer_token` → `access_token`

**Files:**
- Modify: `lib/hunter/client.ex` (struct, @type, docs), `lib/hunter/api/http_client.ex` (`get_headers/1`, `log_in/4`, `log_in_oauth/3` constructors), doc examples in `lib/hunter.ex`, `lib/hunter/instance.ex`, `lib/hunter/account.ex`, `lib/hunter/card.ex`, `README.md`, `CHANGELOG.md`
- Modify (tests): `test/support/integration_case.ex` and every unit test file constructing a client: `test/hunter/{account,attachment,card,client,context,domain,instance,notification,relationship,report,result,status}_test.exs`

**Interfaces:**
- Produces: `%Hunter.Client{base_url: String.t(), access_token: String.t()}` — Tasks 4-5 build clients with `access_token:`.

- [ ] **Step 1: Mechanical rename** — replace the atom/field `bearer_token` with `access_token` in every file above. The complete list of change kinds:
  - `lib/hunter/client.ex`: `defstruct [:base_url, :access_token]`, the `@type t` field, and both mentions in the moduledoc/`new/1` `## Options` docs.
  - `lib/hunter/api/http_client.ex`: `defp get_headers(%Hunter.Client{access_token: token})`, and the two `%Hunter.Client{base_url: base_url, access_token: response["access_token"]}` constructors in `log_in/4` / `log_in_oauth/3`.
  - Doc examples (`iex> Hunter.Client.new(bearer_token: …)`) in `lib/hunter.ex`, `lib/hunter/instance.ex`, `lib/hunter/account.ex`, `lib/hunter/card.ex` → `access_token:`.
  - Every test file's `@conn Hunter.Client.new(base_url: "https://example.com", access_token: "123456")`, `client_test.exs`'s construction + assertion (`%Client{base_url: …, access_token: "123456"}`), and `integration_case.ex`'s two `Hunter.Client.new(base_url: base_url, access_token: token)` calls.
  - `README.md`: every `bearer_token` occurrence in examples/prose.

Use per-file edits, not a blind repo-wide sed — the string `"access_token"` (the JSON response key in `http_client.ex`) must stay untouched, and CHANGELOG/docs specs are out of scope.

- [ ] **Step 2: Verify the rename is total**

Run: `git grep -n "bearer_token" -- lib test README.md`
Expected: no output.

- [ ] **Step 3: CHANGELOG breaking entry** — append to the `* Breaking changes` list in `## Unreleased`:

```markdown
    - `Hunter.Client` field `bearer_token` was renamed to `access_token` for
      consistency with other Mastodon client libraries; update
      `Hunter.Client.new(bearer_token: …)` calls to `access_token:` ([#101])
```

with `[#101]: https://github.com/milmazz/hunter/issues/101` added to the link references.

- [ ] **Step 4: Full gate**

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`
Expected: green — 4 doctests, 76 tests (`--warnings-as-errors` plus the doctests catch any straggler).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "rename Client.bearer_token to access_token

BREAKING: aligns with other Mastodon client libraries (#101).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 3: `Hunter.Application.scopes` + `create_app` stores requested scopes (TDD)

**Files:**
- Modify: `lib/hunter/application.ex` (struct/@type/docs), `lib/hunter/api/http_client.ex:70-81` (`create_app/5`)
- Test: `test/hunter/application_test.exs`

**Interfaces:**
- Produces: `%Hunter.Application{id, client_id, client_secret, scopes :: [String.t()] | nil}` — Task 4's `log_in` reads `scopes`; persistence via the existing `save_credentials`/`load_credentials` picks the field up automatically (Poison encodes/decodes struct fields).

- [ ] **Step 1: Extend the persistence tests (failing first)** — in `test/hunter/application_test.exs`, the existing "store credentials" and "load persisted" tests build `%Hunter.Application{…}` values; add `scopes: ["read", "write"]` to the constructed app in BOTH tests and assert the loaded struct round-trips it:

```elixir
      assert %Hunter.Application{scopes: ["read", "write"]} = loaded
```

(match the test file's existing local variable names — read the file first; the assertion target is whatever `load_credentials` returns there).

- [ ] **Step 2: Run to verify failure**

Run: `mix test test/hunter/application_test.exs`
Expected: FAIL — `scopes` is not a key of `Hunter.Application` (KeyError at construction).

- [ ] **Step 3: Add the field** — `lib/hunter/application.ex`:

```elixir
  defstruct [:id, :client_id, :client_secret, :scopes]
```

extend the `@type t` with `scopes: [String.t()] | nil` and add a `* scopes - scopes requested when the app was registered` line to the fields doc.

- [ ] **Step 4: Store requested scopes in `create_app`** — `lib/hunter/api/http_client.ex`:

```elixir
  def create_app(name, redirect_uri, scopes, website, base_url) do
    payload = %{
      client_name: name,
      redirect_uris: redirect_uri,
      scopes: Enum.join(scopes, " "),
      website: website
    }

    app =
      "/api/v1/apps"
      |> process_url(base_url)
      |> request!(:application, :post, payload)

    %Hunter.Application{app | scopes: scopes}
  end
```

(The requested list is authoritative — the v1 apps response cannot be trusted to echo scopes across server versions.)

- [ ] **Step 5: Full gate and commit**

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`
Expected: green.

```bash
git add lib/hunter/application.ex lib/hunter/api/http_client.ex test/hunter/application_test.exs
git commit -m "record requested scopes on Hunter.Application

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 4: `log_in/4` sends the app's scopes (#100 fix)

**Files:**
- Modify: `lib/hunter/api/http_client.ex` (`log_in/4`, around line 288), `CHANGELOG.md`

**Interfaces:**
- Consumes: `Hunter.Application.scopes` from Task 3.

- [ ] **Step 1: Rewrite `log_in/4`**

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

    response =
      "/oauth/token"
      |> process_url(base_url)
      |> request!(nil, :post, payload)

    %Hunter.Client{base_url: base_url, access_token: response["access_token"]}
  end
```

(Behavior for `scopes: nil`/`[]` — the parameter is omitted, byte-identical to today, so stale saved credential files keep working. This is unit-untestable without a network; the live proof is Task 5.)

- [ ] **Step 2: CHANGELOG bug-fix entry** — append under the `* Bug fixes` block from Task 1:

```markdown
    - `Hunter.log_in/4` now requests the scopes the app was registered with;
      previously the token silently fell back to Mastodon's default `read`
      scope, making every write action fail with "This action is outside the
      authorized scopes" ([#100]). Re-run `create_app` once to refresh saved
      credentials created by older hunter versions.
```

with `[#100]: https://github.com/milmazz/hunter/issues/100` in the link references.

- [ ] **Step 3: Full gate and commit**

Run: `mix compile --warnings-as-errors && mix test && mix format --check-formatted && mix credo --strict`
Expected: green.

```bash
git add lib/hunter/api/http_client.ex CHANGELOG.md
git commit -m "request the app's registered scopes in the password grant

Fixes the read-only tokens behind issue #100.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 5: known password in the stack + live README-flow regression test

**Files:**
- Modify: `scripts/ci/setup_mastodon.sh`, `test/support/integration_case.ex`, `test/integration/mastodon_test.exs`

**Interfaces:**
- Produces: `HUNTER_PASSWORD2` env var (kadaba's password) in `scripts/ci/.env.hunter` and `$GITHUB_ENV`; `password2` in the integration context.

- [ ] **Step 1: setup script** — in `scripts/ci/setup_mastodon.sh`, after `TOKEN2=$(mint_token kadaba)`, add:

```bash
PASSWORD2=$($COMPOSE exec -T web bin/tootctl accounts modify kadaba --reset-password \
  | awk '/New password:/ {print $3}')
```

and extend both output blocks: add `export HUNTER_PASSWORD2=$PASSWORD2` to the `$HUNTER_ENV` heredoc and `echo "HUNTER_PASSWORD2=$PASSWORD2"` to the `$GITHUB_ENV` block.

- [ ] **Step 2: integration case** — in `test/support/integration_case.ex` `setup_all`, add `password2 = fetch_env!("HUNTER_PASSWORD2")` next to the other three, and `password2: password2` to the returned context keyword list. Update the module's `@moduledoc` env-var list to mention it.

- [ ] **Step 3: the regression test** — append to `test/integration/mastodon_test.exs`:

```elixir
  test "README auth flow: create_app + log_in yields a token that can write", %{
    conn: conn,
    password2: password2
  } do
    app =
      Hunter.create_app(
        "hunter-auth-#{System.unique_integer([:positive])}",
        "urn:ietf:wg:oauth:2.0:oob",
        ["read", "write"],
        nil,
        api_base_url: conn.base_url
      )

    assert %Hunter.Application{scopes: ["read", "write"]} = app

    logged_in = Hunter.log_in(app, "kadaba@example.com", password2, conn.base_url)
    assert %Hunter.Client{access_token: token} = logged_in
    assert is_binary(token)

    %Status{id: id} = Status.create_status(logged_in, "auth flow works #hunterci")
    Status.destroy_status(logged_in, id)
  end
```

Before finalizing, confirm `Hunter.create_app/5` and `Hunter.log_in/4` delegate with these exact signatures (`grep -n "create_app\|def log_in\|defdelegate log_in" lib/hunter.ex`); adjust the calls if the top-level arity differs.

- [ ] **Step 4: Run live** (this test FAILS against the pre-Task-4 code with the #100 error — if you want the red-state proof, run it once with Task 4's `log_in` change stashed; otherwise proceed):

Run: `./scripts/ci/setup_mastodon.sh && bash -c 'source scripts/ci/.env.hunter && mix test --only integration'`
Expected: 10 tests, 0 failures. (The setup script must be re-run so `.env.hunter` gains `HUNTER_PASSWORD2` — the older env file will make `setup_all` raise its helpful error.)

- [ ] **Step 5: Unit gate and commit**

Run: `mix test && mix format --check-formatted && mix credo --strict`
Expected: green (integration excluded).

```bash
git add scripts/ci/setup_mastodon.sh test/support/integration_case.ex test/integration/mastodon_test.exs
git commit -m "cover the README auth flow live: create_app, log_in, write

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 6: dialyzer, PR, follow-up issue

- [ ] **Step 1: Dialyzer** (struct/type changes across Tasks 2-4):

Run: `mix dialyzer`
Expected: clean. Fix any finding before pushing (likely candidates: the changed `log_in/4` head or the new `scopes` type).

- [ ] **Step 2: Push and open the PR**

```bash
git push -u origin auth-fixes
gh pr create --base main --title "Auth fixes: request registered scopes on log_in; rename to access_token" --body "$(cat <<'EOF'
Fixes #100. Closes #101.

- `log_in/4` now sends the app's registered scopes in the password grant. Previously the `scope` parameter was omitted, so Doorkeeper granted Mastodon's default `read` scope and every write action failed with "This action is outside the authorized scopes" — reproduced and verified live against Mastodon v4.3.8. `Hunter.Application` records the requested scopes (persisted by `save?: true`); stale credential files (`scopes: nil`) keep the old behavior until `create_app` is re-run.
- BREAKING: `Hunter.Client.bearer_token` → `access_token` (#101), aligned with other Mastodon client libraries.
- New live integration test covers the README auth flow end to end (create_app → log_in → post → delete), using a known password minted by the setup script (`HUNTER_PASSWORD2`).
- Restores the #74 changelog entry dropped in the #109 rebase-merge.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 3: File the deferred `log_in_oauth` issue**

```bash
gh issue create --title "log_in_oauth: token exchange sends no redirect_uri" --body "$(cat <<'EOF'
Noticed while fixing #100: `Hunter.Api.HTTPClient.log_in_oauth/3` exchanges the authorization code without a `redirect_uri` parameter. Doorkeeper requires the token request's `redirect_uri` to match the authorization request's for the authorization_code grant, so this flow likely fails against real servers. Unverified (needs a browser authorization dance) — verify against the docker stack and fix; scopes for this grant come from the authorization itself, so no scope parameter is needed.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 4: Watch checks**

Run: `gh pr checks --watch`
Expected: all 5 jobs green — note the integration job re-provisions from scratch, which exercises the new `HUNTER_PASSWORD2` script path in CI.
