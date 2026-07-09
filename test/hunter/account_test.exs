defmodule Hunter.AccountTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Account

  @conn Hunter.new(base_url: "https://mastodon.example", access_token: "123456")

  test "verify credentials returns the authenticated account" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/accounts/verify_credentials"
      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer 123456"]
      respond_with_fixture(conn, "account")
    end)

    assert %Account{username: "milmazz", followers_count: 118} =
             Hunter.verify_credentials(@conn)
  end

  test "updates authenticated user's credentials with a JSON body" do
    stub_request(fn conn ->
      assert conn.method == "PATCH"
      assert conn.request_path == "/api/v1/accounts/update_credentials"
      assert %{"note" => "new bio"} = read_json_body!(conn)
      respond_with_fixture(conn, "account")
    end)

    assert %Account{username: "milmazz"} = Hunter.update_credentials(@conn, %{note: "new bio"})
  end

  test "returns an account" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/accounts/23634"
      respond_with_fixture(conn, "account")
    end)

    assert %Account{username: "milmazz", acct: "milmazz"} = Hunter.account(@conn, 23_634)
  end

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

  test "returns a collection of followers with query params" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/accounts/23634/followers"
      assert conn.query_string == "limit=1"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{username: "milmazz"}] = Hunter.followers(@conn, 23_634, limit: 1)
  end

  test "returns a collection of followed accounts with query params" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/accounts/23634/following"
      assert conn.query_string == "limit=1"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{username: "milmazz"}] = Hunter.following(@conn, 23_634, limit: 1)
  end

  test "searches for accounts with the q param and a default limit" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/accounts/search"
      assert conn.query_string =~ "q=milmazz"
      assert conn.query_string =~ "limit=40"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{username: "milmazz"}] = Hunter.search_account(@conn, q: "milmazz")
  end

  test "returns blocked accounts" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/blocks"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{}] = Hunter.blocks(@conn)
  end

  test "returns follow requests" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/follow_requests"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{}] = Hunter.follow_requests(@conn)
  end

  test "returns muted accounts" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/mutes"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{}] = Hunter.mutes(@conn)
  end

  test "accepts a follow request" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/follow_requests/8039/authorize"
      respond_with_fixture(conn, "relationship")
    end)

    assert %Hunter.Relationship{id: "8039"} = Hunter.accept_follow_request(@conn, 8039)
  end

  test "rejects a follow request" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/follow_requests/8039/reject"
      respond_with_fixture(conn, "relationship")
    end)

    assert %Hunter.Relationship{id: "8039"} = Hunter.reject_follow_request(@conn, 8039)
  end

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

  test "returns the accounts that reblogged a status" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/statuses/153452/reblogged_by"
      assert conn.query_string == "limit=1"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{username: "milmazz"}] = Hunter.reblogged_by(@conn, 153_452, limit: 1)
  end

  test "returns the accounts that favourited a status" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/statuses/153452/favourited_by"
      assert conn.query_string == "limit=1"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{username: "milmazz"}] = Hunter.favourited_by(@conn, 153_452, limit: 1)
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Hunter.account(@conn, 0) end
  end
end
