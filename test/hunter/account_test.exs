defmodule Hunter.AccountTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Account

  @conn Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")

  setup :verify_on_exit!

  test "verify credentials" do
    expect(Hunter.ApiMock, :verify_credentials, fn %Hunter.Client{} ->
      %Account{username: "milmazz"}
    end)

    assert %Account{username: "milmazz"} = Account.verify_credentials(@conn)
  end

  test "returns an account" do
    expect(Hunter.ApiMock, :account, fn %Hunter.Client{}, _id ->
      %Account{username: "milmazz"}
    end)

    assert %Account{username: "milmazz"} = Account.account(@conn, 8039)
  end

  test "returns a collection of followers accounts" do
    expect(Hunter.ApiMock, :followers, fn %Hunter.Client{}, _id, _opts ->
      [%Account{username: "kadaba"}]
    end)

    assert [%Account{username: "kadaba"} | _] = Account.followers(@conn, 8039)
  end

  test "returns a collection of following accounts" do
    expect(Hunter.ApiMock, :following, fn %Hunter.Client{}, _id, _opts ->
      [%Account{username: "paperswelove"}]
    end)

    assert [%Account{username: "paperswelove"} | _] = Account.following(@conn, 8039)
  end

  test "following a remote user" do
    expect(Hunter.ApiMock, :follow_by_uri, fn %Hunter.Client{}, _id ->
      %Account{username: "paperswelove"}
    end)

    assert %Account{username: "paperswelove"} =
             Account.follow_by_uri(@conn, "paperswelove@mstdn.io")
  end

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

    assert [%Account{username: "milmazz"}] = Account.search_account(@conn, q: "milmazz")
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
end
