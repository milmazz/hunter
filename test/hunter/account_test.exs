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
             Account.verify_credentials(@conn)
  end

  test "updates authenticated user's credentials with a JSON body" do
    stub_request(fn conn ->
      assert conn.method == "PATCH"
      assert conn.request_path == "/api/v1/accounts/update_credentials"
      assert %{"note" => "new bio"} = read_json_body!(conn)
      respond_with_fixture(conn, "account")
    end)

    assert %Account{username: "milmazz"} = Account.update_credentials(@conn, %{note: "new bio"})
  end

  test "returns an account" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/accounts/23634"
      respond_with_fixture(conn, "account")
    end)

    assert %Account{username: "milmazz", acct: "milmazz"} = Account.account(@conn, 23_634)
  end

  test "returns a collection of followers with query params" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/accounts/23634/followers"
      assert conn.query_string == "limit=1"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{username: "milmazz"}] = Account.followers(@conn, 23_634, limit: 1)
  end

  test "returns a collection of followed accounts with query params" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/accounts/23634/following"
      assert conn.query_string == "limit=1"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{username: "milmazz"}] = Account.following(@conn, 23_634, limit: 1)
  end

  test "searches for accounts with the q param and a default limit" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/accounts/search"
      assert conn.query_string =~ "q=milmazz"
      assert conn.query_string =~ "limit=40"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{username: "milmazz"}] = Account.search_account(@conn, q: "milmazz")
  end

  test "returns blocked accounts" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/blocks"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{}] = Account.blocks(@conn)
  end

  test "returns follow requests" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/follow_requests"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{}] = Account.follow_requests(@conn)
  end

  test "returns muted accounts" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/mutes"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{}] = Account.mutes(@conn)
  end

  test "accepts a follow request" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/follow_requests/8039/authorize"
      respond_with_fixture(conn, "relationship")
    end)

    assert %Hunter.Relationship{id: "8039"} = Account.accept_follow_request(@conn, 8039)
  end

  test "rejects a follow request" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/follow_requests/8039/reject"
      respond_with_fixture(conn, "relationship")
    end)

    assert %Hunter.Relationship{id: "8039"} = Account.reject_follow_request(@conn, 8039)
  end

  test "returns the accounts that reblogged a status" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/statuses/153452/reblogged_by"
      assert conn.query_string == "limit=1"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{username: "milmazz"}] = Account.reblogged_by(@conn, 153_452, limit: 1)
  end

  test "returns the accounts that favourited a status" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/statuses/153452/favourited_by"
      assert conn.query_string == "limit=1"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Account{username: "milmazz"}] = Account.favourited_by(@conn, 153_452, limit: 1)
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Account.account(@conn, 0) end
  end
end
