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
end
