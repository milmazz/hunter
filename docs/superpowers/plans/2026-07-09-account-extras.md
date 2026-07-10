# Account Extras Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expose eleven account-level Mastodon endpoints Hunter is missing: lookup/fetch, registration, relationship extras (note, remove-from-followers), and endorsements (issue #124).

**Architecture:** Each endpoint is a thin function on the `Hunter` module (`lib/hunter.ex`) that delegates to `Hunter.Api.Request.request!/4-6`, exactly like the existing `account/2`, `followers/3`, `relationships/2`, `follow/2`. Responses decode through `Hunter.Api.Transformer` target atoms into existing entity structs. One new entity, `Hunter.FamiliarFollowers`, because that response is a distinct shape; everything else reuses `Account`, `Relationship`, `FeaturedTag`.

**Tech Stack:** Elixir (1.16+), Req for HTTP, Poison for JSON. Tests use ExUnit with `Req.Test` stubs via the `Hunter.ReqCase` case template.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-07-09-account-extras-design.md`. All eleven endpoints ship in a single PR (branch `account-extras-124`).
- One module per file; folders mirror the module hierarchy (no nested `defmodule`).
- Entity `id` fields are typed `String.t()`; id *parameters* accept `String.t() | non_neg_integer`.
- No `Hunter.Token` entity — registration returns a `Hunter.Client`.
- The deprecated account `pin`/`unpin` endorsement endpoints are NOT implemented.
- Run `mix format` before every commit. Full check: `mix test`, `mix credo`, `mix dialyzer`.
- Test conventions: `test/hunter/account_test.exs` uses `@conn Hunter.new(base_url: "https://mastodon.example", access_token: "123456")` and helpers `stub_request/1`, `respond_with_fixture/2-3`, `respond_with/2-3`, `read_json_body!/1` from `Hunter.ReqCase`. Repeated list params are asserted with `URI.encode_query([{"id[]", "1"}, ...])`.

### Where things live (orientation for every task)

- `lib/hunter.ex` — the facade; all endpoint functions. Every function follows this shape:

  ```elixir
  @doc """
  Follow a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec follow(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Relationship.t()
  def follow(conn, id) do
    Request.request!(conn, :post, "/api/v1/accounts/#{id}/follow", :relationship)
  end
  ```

  `Request` is already aliased at the top of the module. `request!(conn, method, path, transformer_target, payload \\ [], opts \\ [])`: for `:get` the payload becomes query params (a list value expands to repeated `key[]=` params); for `:post` it becomes a JSON body. Transformer target `nil` returns the JSON-decoded body as a plain map.

- `lib/hunter/api/transformer.ex` — `Hunter.Api.Transformer.transform/2` clauses, one per target atom. Existing targets used here: `:account`, `:accounts`, `:relationship`, `:featured_tags`. Private helper `account_nested_struct/0` builds `%Hunter.Account{emojis: [...], fields: [...], roles: [...]}` for nested decoding.

- Fixtures: `test/fixtures/account.json` (id `"23634"`, username `"milmazz"`), `test/fixtures/relationship.json` (id `"8039"`, `note: "college friend"`), `test/fixtures/featured_tag.json` (id `"627"`, name `"elixir"`).

---

### Task 1: `Hunter.FamiliarFollowers` entity + transformer clause

**Files:**
- Create: `lib/hunter/familiar_followers.ex`
- Create: `test/fixtures/familiar_followers.json`
- Modify: `lib/hunter/api/transformer.ex`
- Test: `test/hunter/api/transformer_test.exs`

**Interfaces:**
- Consumes: `Hunter.Account` struct, `account_nested_struct/0` private helper in `Hunter.Api.Transformer`.
- Produces: `Hunter.FamiliarFollowers` struct with fields `id :: String.t()`, `accounts :: [Hunter.Account.t()]`; transformer target `:familiar_followers` that decodes a JSON **array** into `[%Hunter.FamiliarFollowers{}]`. Task 3 relies on both.

- [ ] **Step 1: Create the fixture**

Create `test/fixtures/familiar_followers.json` — note the top level is an array:

```json
[
  {
    "id": "8039",
    "accounts": [
      {
        "id": "23634",
        "username": "milmazz",
        "acct": "milmazz",
        "display_name": "Milton Mazzarri",
        "url": "https://mastodon.example/@milmazz"
      }
    ]
  }
]
```

- [ ] **Step 2: Write the failing transformer test**

In `test/hunter/api/transformer_test.exs`, add after the `"decodes a list of featured tags"` test (uses the existing `transform/2` private helper at the bottom of the file — NOT `transform_list/2`, because the fixture is already an array):

```elixir
test "decodes familiar followers with nested accounts" do
  assert [familiar] = transform("familiar_followers", :familiar_followers)

  assert %Hunter.FamiliarFollowers{id: "8039"} = familiar
  assert [%Hunter.Account{username: "milmazz", acct: "milmazz"}] = familiar.accounts
end
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `mix test test/hunter/api/transformer_test.exs`
Expected: FAIL — the `:familiar_followers` target falls through to the catch-all `transform(body, _)` clause and returns plain maps, so the `%Hunter.FamiliarFollowers{}` match fails (the struct doesn't exist yet either).

- [ ] **Step 4: Create the entity module**

Create `lib/hunter/familiar_followers.ex`:

```elixir
defmodule Hunter.FamiliarFollowers do
  @moduledoc """
  FamiliarFollowers entity

  Accounts you follow that also follow a given account

  ## Fields

    * `id` - the account id these familiar followers relate to
    * `accounts` - accounts you follow that also follow that account

  """

  @type t :: %__MODULE__{
          id: String.t(),
          accounts: [Hunter.Account.t()]
        }

  @derive [Poison.Encoder]
  defstruct [:id, :accounts]
end
```

- [ ] **Step 5: Add the transformer clause**

In `lib/hunter/api/transformer.ex`, add directly after the `transform(body, :accounts)` clause:

```elixir
def transform(body, :familiar_followers),
  do: Poison.decode!(body, as: [%Hunter.FamiliarFollowers{accounts: [account_nested_struct()]}])
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `mix test test/hunter/api/transformer_test.exs`
Expected: PASS (all tests in the file).

- [ ] **Step 7: Format and commit**

```bash
mix format
git add lib/hunter/familiar_followers.ex lib/hunter/api/transformer.ex test/fixtures/familiar_followers.json test/hunter/api/transformer_test.exs
git commit -m "feat: add Hunter.FamiliarFollowers entity and transformer target"
```

---

### Task 2: `lookup_account/2` and `accounts_by_ids/2`

**Files:**
- Modify: `lib/hunter.ex`
- Test: `test/hunter/account_test.exs`

**Interfaces:**
- Consumes: `Request.request!/5` (aliased in `lib/hunter.ex`), transformer targets `:account` and `:accounts`.
- Produces: `Hunter.lookup_account(conn, acct) :: Hunter.Account.t()` and `Hunter.accounts_by_ids(conn, ids) :: [Hunter.Account.t()]`.

- [ ] **Step 1: Write the failing tests**

In `test/hunter/account_test.exs`, add after the `"returns an account"` test:

```elixir
test "looks up an account by acct" do
  stub_request(fn conn ->
    assert conn.method == "GET"
    assert conn.request_path == "/api/v1/accounts/lookup"
    assert conn.query_string == URI.encode_query([{"acct", "milmazz@mastodon.example"}])
    respond_with_fixture(conn, "account")
  end)

  assert %Account{username: "milmazz"} =
           Hunter.lookup_account(@conn, "milmazz@mastodon.example")
end

test "returns multiple accounts by id with id[] params" do
  stub_request(fn conn ->
    assert conn.method == "GET"
    assert conn.request_path == "/api/v1/accounts"
    assert conn.query_string == URI.encode_query([{"id[]", "1"}, {"id[]", "2"}])
    respond_with_fixture(conn, "account", wrap: :list)
  end)

  assert [%Account{username: "milmazz"}] = Hunter.accounts_by_ids(@conn, [1, 2])
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `mix test test/hunter/account_test.exs`
Expected: FAIL with `UndefinedFunctionError` for `Hunter.lookup_account/2` and `Hunter.accounts_by_ids/2`.

- [ ] **Step 3: Implement the functions**

In `lib/hunter.ex`, add directly after the `account/2` function (search for `def account(conn, id) do`; insert after its closing `end`):

```elixir
@doc """
Look up an account by its webfinger address, without requiring a search

## Parameters

  * `conn` - connection credentials
  * `acct` - the username or webfinger address (e.g. `user@domain`) to look up

"""
@spec lookup_account(Hunter.Client.t(), String.t()) :: Hunter.Account.t()
def lookup_account(conn, acct) do
  Request.request!(conn, :get, "/api/v1/accounts/lookup", :account, %{acct: acct})
end

@doc """
Retrieve multiple accounts by id

## Parameters

  * `conn` - connection credentials
  * `ids` - list of account identifiers

"""
@spec accounts_by_ids(Hunter.Client.t(), [String.t() | non_neg_integer]) :: [Hunter.Account.t()]
def accounts_by_ids(conn, ids) do
  Request.request!(conn, :get, "/api/v1/accounts", :accounts, %{id: ids})
end
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `mix test test/hunter/account_test.exs`
Expected: PASS (all tests in the file).

- [ ] **Step 5: Format and commit**

```bash
mix format
git add lib/hunter.ex test/hunter/account_test.exs
git commit -m "feat: add lookup_account/2 and accounts_by_ids/2"
```

---

### Task 3: `familiar_followers/2` and `account_featured_tags/2`

**Files:**
- Modify: `lib/hunter.ex`
- Test: `test/hunter/account_test.exs`

**Interfaces:**
- Consumes: `Request.request!/4-5`, transformer targets `:familiar_followers` (added in Task 1) and `:featured_tags` (already exists), `Hunter.FamiliarFollowers` struct (Task 1), `test/fixtures/familiar_followers.json` (Task 1).
- Produces: `Hunter.familiar_followers(conn, ids) :: [Hunter.FamiliarFollowers.t()]` and `Hunter.account_featured_tags(conn, id) :: [Hunter.FeaturedTag.t()]`.

- [ ] **Step 1: Write the failing tests**

In `test/hunter/account_test.exs`, add after the `accounts_by_ids` test added in Task 2 (if executing out of order, add after the `"returns an account"` test):

```elixir
test "returns familiar followers with id[] params" do
  stub_request(fn conn ->
    assert conn.method == "GET"
    assert conn.request_path == "/api/v1/accounts/familiar_followers"
    assert conn.query_string == URI.encode_query([{"id[]", "8039"}, {"id[]", "8040"}])
    respond_with_fixture(conn, "familiar_followers")
  end)

  assert [%Hunter.FamiliarFollowers{id: "8039", accounts: [%Account{username: "milmazz"}]}] =
           Hunter.familiar_followers(@conn, [8039, 8040])
end

test "returns an account's featured tags" do
  stub_request(fn conn ->
    assert conn.method == "GET"
    assert conn.request_path == "/api/v1/accounts/23634/featured_tags"
    respond_with_fixture(conn, "featured_tag", wrap: :list)
  end)

  assert [%Hunter.FeaturedTag{name: "elixir", statuses_count: 20}] =
           Hunter.account_featured_tags(@conn, 23_634)
end
```

Note: `familiar_followers.json` is already a JSON array, so no `wrap: :list` there.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `mix test test/hunter/account_test.exs`
Expected: FAIL with `UndefinedFunctionError` for `Hunter.familiar_followers/2` and `Hunter.account_featured_tags/2`.

- [ ] **Step 3: Implement the functions**

In `lib/hunter.ex`, add directly after the `following/3` function (search for `def following(conn, id, options \\ []) do`; insert after its closing `end`):

```elixir
@doc """
Find out which of the accounts you follow also follow the given accounts

## Parameters

  * `conn` - connection credentials
  * `ids` - list of account identifiers

"""
@spec familiar_followers(Hunter.Client.t(), [String.t() | non_neg_integer]) :: [
        Hunter.FamiliarFollowers.t()
      ]
def familiar_followers(conn, ids) do
  Request.request!(conn, :get, "/api/v1/accounts/familiar_followers", :familiar_followers, %{
    id: ids
  })
end

@doc """
Retrieve the hashtags an account is featuring on their profile

## Parameters

  * `conn` - connection credentials
  * `id` - account identifier

"""
@spec account_featured_tags(Hunter.Client.t(), String.t() | non_neg_integer) :: [
        Hunter.FeaturedTag.t()
      ]
def account_featured_tags(conn, id) do
  Request.request!(conn, :get, "/api/v1/accounts/#{id}/featured_tags", :featured_tags)
end
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `mix test test/hunter/account_test.exs`
Expected: PASS (all tests in the file).

- [ ] **Step 5: Format and commit**

```bash
mix format
git add lib/hunter.ex test/hunter/account_test.exs
git commit -m "feat: add familiar_followers/2 and account_featured_tags/2"
```

---

### Task 4: `set_account_note/3` and `remove_from_followers/2`

**Files:**
- Modify: `lib/hunter.ex`
- Test: `test/hunter/account_test.exs`

**Interfaces:**
- Consumes: `Request.request!/4-5`, transformer target `:relationship`, fixture `relationship.json` (id `"8039"`, `note: "college friend"`).
- Produces: `Hunter.set_account_note(conn, id, comment) :: Hunter.Relationship.t()` and `Hunter.remove_from_followers(conn, id) :: Hunter.Relationship.t()`.

- [ ] **Step 1: Write the failing tests**

In `test/hunter/account_test.exs`, add after the `"rejects a follow request"` test:

```elixir
test "sets a private note on an account" do
  stub_request(fn conn ->
    assert conn.method == "POST"
    assert conn.request_path == "/api/v1/accounts/8039/note"
    assert %{"comment" => "college friend"} = read_json_body!(conn)
    respond_with_fixture(conn, "relationship")
  end)

  assert %Hunter.Relationship{id: "8039", note: "college friend"} =
           Hunter.set_account_note(@conn, 8039, "college friend")
end

test "removes an account from your followers" do
  stub_request(fn conn ->
    assert conn.method == "POST"
    assert conn.request_path == "/api/v1/accounts/8039/remove_from_followers"
    respond_with_fixture(conn, "relationship")
  end)

  assert %Hunter.Relationship{id: "8039"} = Hunter.remove_from_followers(@conn, 8039)
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `mix test test/hunter/account_test.exs`
Expected: FAIL with `UndefinedFunctionError` for `Hunter.set_account_note/3` and `Hunter.remove_from_followers/2`.

- [ ] **Step 3: Implement the functions**

In `lib/hunter.ex`, add directly after the `unfollow/2` function (search for `def unfollow(conn, id) do`; insert after its closing `end`):

```elixir
@doc """
Set a private note on an account

## Parameters

  * `conn` - connection credentials
  * `id` - account identifier
  * `comment` - the note text; pass an empty string to clear the note

"""
@spec set_account_note(Hunter.Client.t(), String.t() | non_neg_integer, String.t()) ::
        Hunter.Relationship.t()
def set_account_note(conn, id, comment) do
  Request.request!(conn, :post, "/api/v1/accounts/#{id}/note", :relationship, %{
    comment: comment
  })
end

@doc """
Remove an account from your followers

## Parameters

  * `conn` - connection credentials
  * `id` - account identifier

"""
@spec remove_from_followers(Hunter.Client.t(), String.t() | non_neg_integer) ::
        Hunter.Relationship.t()
def remove_from_followers(conn, id) do
  Request.request!(conn, :post, "/api/v1/accounts/#{id}/remove_from_followers", :relationship)
end
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `mix test test/hunter/account_test.exs`
Expected: PASS (all tests in the file).

- [ ] **Step 5: Format and commit**

```bash
mix format
git add lib/hunter.ex test/hunter/account_test.exs
git commit -m "feat: add set_account_note/3 and remove_from_followers/2"
```

---

### Task 5: Endorsements — `endorse/2`, `unendorse/2`, `endorsements/2`, `account_endorsements/3`

**Files:**
- Modify: `lib/hunter.ex`
- Test: `test/hunter/account_test.exs`

**Interfaces:**
- Consumes: `Request.request!/4-5`, transformer targets `:relationship` and `:accounts`.
- Produces: `Hunter.endorse(conn, id) :: Hunter.Relationship.t()`, `Hunter.unendorse(conn, id) :: Hunter.Relationship.t()`, `Hunter.endorsements(conn, opts \\ []) :: [Hunter.Account.t()]`, `Hunter.account_endorsements(conn, id, opts \\ []) :: [Hunter.Account.t()]`.

Naming rationale (from the spec): `endorse`/`unendorse` parallel `follow`/`unfollow`. The existing `pin`/`unpin` on `Hunter` act on *statuses*, so there is no collision, and the deprecated account `pin`/`unpin` variants are not implemented. `endorsements/2` (your featured accounts) and `account_endorsements/3` (a given account's featured accounts) are distinct endpoints with distinct names.

- [ ] **Step 1: Write the failing tests**

In `test/hunter/account_test.exs`, add after the `remove_from_followers` test added in Task 4 (if executing out of order, add after the `"rejects a follow request"` test):

```elixir
test "endorses an account" do
  stub_request(fn conn ->
    assert conn.method == "POST"
    assert conn.request_path == "/api/v1/accounts/8039/endorse"
    respond_with_fixture(conn, "relationship")
  end)

  assert %Hunter.Relationship{id: "8039"} = Hunter.endorse(@conn, 8039)
end

test "removes an account endorsement" do
  stub_request(fn conn ->
    assert conn.method == "POST"
    assert conn.request_path == "/api/v1/accounts/8039/unendorse"
    respond_with_fixture(conn, "relationship")
  end)

  assert %Hunter.Relationship{id: "8039"} = Hunter.unendorse(@conn, 8039)
end

test "returns your endorsed accounts with query params" do
  stub_request(fn conn ->
    assert conn.method == "GET"
    assert conn.request_path == "/api/v1/endorsements"
    assert conn.query_string == "limit=1"
    respond_with_fixture(conn, "account", wrap: :list)
  end)

  assert [%Account{username: "milmazz"}] = Hunter.endorsements(@conn, limit: 1)
end

test "returns the accounts a given account is featuring" do
  stub_request(fn conn ->
    assert conn.method == "GET"
    assert conn.request_path == "/api/v1/accounts/8039/endorsements"
    assert conn.query_string == "limit=1"
    respond_with_fixture(conn, "account", wrap: :list)
  end)

  assert [%Account{username: "milmazz"}] = Hunter.account_endorsements(@conn, 8039, limit: 1)
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `mix test test/hunter/account_test.exs`
Expected: FAIL with `UndefinedFunctionError` for `Hunter.endorse/2`, `Hunter.unendorse/2`, `Hunter.endorsements/2`, `Hunter.account_endorsements/3`.

- [ ] **Step 3: Implement the functions**

In `lib/hunter.ex`, add directly after the `remove_from_followers/2` function added in Task 4 (if executing out of order, add after `unfollow/2`'s closing `end`):

```elixir
@doc """
Feature an account on your profile

## Parameters

  * `conn` - connection credentials
  * `id` - account identifier

"""
@spec endorse(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Relationship.t()
def endorse(conn, id) do
  Request.request!(conn, :post, "/api/v1/accounts/#{id}/endorse", :relationship)
end

@doc """
Stop featuring an account on your profile

## Parameters

  * `conn` - connection credentials
  * `id` - account identifier

"""
@spec unendorse(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Relationship.t()
def unendorse(conn, id) do
  Request.request!(conn, :post, "/api/v1/accounts/#{id}/unendorse", :relationship)
end

@doc """
Retrieve the accounts you are featuring on your profile

## Parameters

  * `conn` - connection credentials
  * `options` - option list

## Options

  * `max_id` - get a list of endorsements with id less than or equal this value
  * `since_id` - get a list of endorsements with id greater than this value
  * `limit` - maximum number of endorsements to get

"""
@spec endorsements(Hunter.Client.t(), Keyword.t()) :: [Hunter.Account.t()]
def endorsements(conn, options \\ []) do
  Request.request!(conn, :get, "/api/v1/endorsements", :accounts, options)
end

@doc """
Retrieve the accounts a given account is featuring on their profile

## Parameters

  * `conn` - connection credentials
  * `id` - account identifier
  * `options` - option list

## Options

  * `max_id` - get a list of endorsements with id less than or equal this value
  * `since_id` - get a list of endorsements with id greater than this value
  * `limit` - maximum number of endorsements to get

"""
@spec account_endorsements(Hunter.Client.t(), String.t() | non_neg_integer, Keyword.t()) :: [
        Hunter.Account.t()
      ]
def account_endorsements(conn, id, options \\ []) do
  Request.request!(conn, :get, "/api/v1/accounts/#{id}/endorsements", :accounts, options)
end
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `mix test test/hunter/account_test.exs`
Expected: PASS (all tests in the file).

- [ ] **Step 5: Format and commit**

```bash
mix format
git add lib/hunter.ex test/hunter/account_test.exs
git commit -m "feat: add endorsement endpoints"
```

---

### Task 6: `register_account/2`

**Files:**
- Modify: `lib/hunter.ex`
- Test: `test/hunter/account_test.exs`

**Interfaces:**
- Consumes: `Request.request!/5` with transformer target `nil` (returns the JSON-decoded body as a plain map — same technique as the existing `log_in/4`, which does `response = Request.request!(base_url, :post, "/oauth/token", nil, payload)` then builds `%Hunter.Client{base_url: base_url, access_token: response["access_token"]}`).
- Produces: `Hunter.register_account(conn, params) :: Hunter.Client.t()`.

Design note (from the spec): the caller passes a `Hunter.Client` carrying the *app-level* access token (obtained from the client-credentials flow). The response is a Token JSON; we return a new `Hunter.Client` with the user-level `access_token`. No `Hunter.Token` entity.

- [ ] **Step 1: Write the failing test**

In `test/hunter/account_test.exs`, add after the `"updates authenticated user's credentials with a JSON body"` test:

```elixir
test "registers an account and returns a client holding the new token" do
  stub_request(fn conn ->
    assert conn.method == "POST"
    assert conn.request_path == "/api/v1/accounts"
    assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer 123456"]

    assert %{
             "username" => "kadaba",
             "email" => "kadaba@example.com",
             "password" => "hunter2hunter2",
             "agreement" => true,
             "locale" => "en"
           } = read_json_body!(conn)

    respond_with(conn, %{
      access_token: "brandnewtoken",
      token_type: "Bearer",
      scope: "read write follow",
      created_at: 1_783_814_400
    })
  end)

  assert %Hunter.Client{base_url: "https://mastodon.example", access_token: "brandnewtoken"} =
           Hunter.register_account(@conn, %{
             username: "kadaba",
             email: "kadaba@example.com",
             password: "hunter2hunter2",
             agreement: true,
             locale: "en"
           })
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mix test test/hunter/account_test.exs`
Expected: FAIL with `UndefinedFunctionError` for `Hunter.register_account/2`.

- [ ] **Step 3: Implement the function**

In `lib/hunter.ex`, add directly before the `log_in/4` function (search for `@spec log_in(`; insert above its `@doc` block):

```elixir
@doc """
Register a new account and obtain its access token

The given client must carry an *app-level* access token (from the OAuth
client-credentials flow); returns a new `Hunter.Client` holding the created
user's access token.

## Parameters

  * `conn` - connection credentials with the app-level access token
  * `params` - registration params

## Possible keys for params

  * `username` - desired username
  * `email` - the account owner's email address
  * `password` - the account password
  * `agreement` - whether the user agrees to the server rules and terms (must be `true`)
  * `locale` - the language of the confirmation email (e.g. `"en"`)
  * `reason` - (optional) why you want to join, when registrations require approval

"""
@spec register_account(Hunter.Client.t(), map) :: Hunter.Client.t()
def register_account(conn, params) do
  response = Request.request!(conn, :post, "/api/v1/accounts", nil, params)

  %Hunter.Client{base_url: conn.base_url, access_token: response["access_token"]}
end
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `mix test test/hunter/account_test.exs`
Expected: PASS (all tests in the file).

- [ ] **Step 5: Format and commit**

```bash
mix format
git add lib/hunter.ex test/hunter/account_test.exs
git commit -m "feat: add register_account/2"
```

---

### Task 7: CHANGELOG entry + full verification

**Files:**
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: all functions from Tasks 1–6.
- Produces: release notes; a fully verified branch.

- [ ] **Step 1: Add the CHANGELOG entry**

In `CHANGELOG.md`, under `## v0.7.0` → `* Features`, add as the FIRST bullet of the Features list (matching the style of the existing `- Notifications v2 ([#122]): ...` entries):

```markdown
    - Account extras ([#124]): `lookup_account/2`, `accounts_by_ids/2`,
      `familiar_followers/2` (new `Hunter.FamiliarFollowers` entity),
      `account_featured_tags/2`, `register_account/2` (returns a
      `Hunter.Client` holding the new user's token), `set_account_note/3`,
      `remove_from_followers/2`, and endorsements (`endorse/2`,
      `unendorse/2`, `endorsements/2`, `account_endorsements/3`), all on
      `Hunter`
```

Then add the link reference next to the existing ones near the bottom of the file (after the line `[#122]: https://github.com/milmazz/hunter/issues/122`):

```markdown
[#124]: https://github.com/milmazz/hunter/issues/124
```

- [ ] **Step 2: Run the full test suite**

Run: `mix test`
Expected: 0 failures.

- [ ] **Step 3: Run the linters**

Run: `mix format --check-formatted && mix credo`
Expected: no formatting diffs, no credo issues in the changed files.

Run: `mix dialyzer`
Expected: no new warnings (first run may take a while building the PLT).

- [ ] **Step 4: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: changelog entry for account extras (#124)"
```

---

## Self-Review Notes

Spec coverage check: all eleven endpoint functions from the spec's table have a task (Task 2: `lookup_account`, `accounts_by_ids`; Task 3: `familiar_followers`, `account_featured_tags`; Task 4: `set_account_note`, `remove_from_followers`; Task 5: `endorse`, `unendorse`, `endorsements`, `account_endorsements`; Task 6: `register_account`). The new entity, transformer clause, fixture, and transformer test are Task 1. One test per endpoint lands in `test/hunter/account_test.exs`; the `register_account` test asserts the app bearer token and returned `Hunter.Client`; the transformer test covers `:familiar_followers`. Out-of-scope items (Token entity, deprecated pin/unpin) are excluded.
