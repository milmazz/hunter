defmodule Hunter.AccountTest do
  use ExUnit.Case, async: true

  alias Hunter.Account

  setup  do
    [conn: Hunter.Client.new([base_url: "https://example.com", bearer_token: "123456"])]
  end

  test "verify credentials", %{conn: conn} do
    assert %Account{username: "milmazz"} = Account.verify_credentials(conn)
  end

  test "returns an account", %{conn: conn} do
    assert %Account{username: "milmazz"} = Account.account(conn, 8039)
  end

  test "returns a collection of followers accounts", %{conn: conn} do
    collection = Account.followers(conn, 8039)
    assert %Account{username: "kadaba"} = List.first(collection)
  end

  test "returns a collection of following accounts", %{conn: conn} do
    collection = Account.following(conn, 8039)
    assert %Account{username: "paperswelove"} = List.first(collection)
  end

  test "following a remote user", %{conn: conn} do
    assert %Account{username: "paperswelove"} = Account.follow_by_uri(conn, "paperswelove@mstdn.io")
  end
end
