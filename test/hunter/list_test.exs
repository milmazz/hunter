defmodule Hunter.ListTest do
  use Hunter.ReqCase, async: true

  alias Hunter.List

  @conn Hunter.new(base_url: "https://mastodon.example", access_token: "123456")

  test "returns all lists the user owns" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/lists"
      respond_with_fixture(conn, "list", wrap: :list)
    end)

    assert [%List{id: "12249", title: "Friends"}] = Hunter.lists(@conn)
  end

  test "returns a single list" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/lists/12249"
      respond_with_fixture(conn, "list")
    end)

    assert %List{id: "12249", replies_policy: "followed"} = Hunter.list(@conn, 12_249)
  end

  test "creates a list with a JSON body" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/lists"
      assert %{"title" => "Friends", "replies_policy" => "followed"} = read_json_body!(conn)
      respond_with_fixture(conn, "list")
    end)

    assert %List{title: "Friends", replies_policy: "followed"} =
             Hunter.create_list(@conn, "Friends", replies_policy: "followed")
  end

  test "updates a list" do
    stub_request(fn conn ->
      assert conn.method == "PUT"
      assert conn.request_path == "/api/v1/lists/12249"
      assert %{"title" => "Close friends", "exclusive" => true} = read_json_body!(conn)
      respond_with_fixture(conn, "list")
    end)

    assert %List{id: "12249"} =
             Hunter.update_list(@conn, 12_249, title: "Close friends", exclusive: true)
  end

  test "destroys a list" do
    stub_request(fn conn ->
      assert conn.method == "DELETE"
      assert conn.request_path == "/api/v1/lists/12249"
      respond_with(conn, %{})
    end)

    assert Hunter.destroy_list(@conn, 12_249) == true
  end

  test "returns accounts in a list" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/lists/12249/accounts"
      assert conn.query_string == "limit=1"
      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Hunter.Account{username: "milmazz"}] =
             Hunter.list_accounts(@conn, 12_249, limit: 1)
  end

  test "adds accounts to a list with a JSON body" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/lists/12249/accounts"
      assert %{"account_ids" => [8039]} = read_json_body!(conn)
      respond_with(conn, %{})
    end)

    assert Hunter.add_accounts_to_list(@conn, 12_249, [8039]) == true
  end

  test "removes accounts from a list via query params" do
    stub_request(fn conn ->
      assert conn.method == "DELETE"
      assert conn.request_path == "/api/v1/lists/12249/accounts"
      assert conn.query_string == URI.encode_query([{"account_ids[]", "8039"}])
      respond_with(conn, %{})
    end)

    assert Hunter.remove_accounts_from_list(@conn, 12_249, [8039]) == true
  end

  test "returns lists containing a given account" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/accounts/8039/lists"
      respond_with_fixture(conn, "list", wrap: :list)
    end)

    assert [%List{title: "Friends"}] = Hunter.account_lists(@conn, 8039)
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Hunter.list(@conn, 0) end
  end
end
