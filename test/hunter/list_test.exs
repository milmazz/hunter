defmodule Hunter.ListTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.List

  @conn Hunter.Client.new(base_url: "https://example.com", access_token: "123456")

  setup :verify_on_exit!

  test "returns all lists the user owns" do
    expect(Hunter.ApiMock, :lists, fn %Hunter.Client{} ->
      [%List{id: "12249", title: "Friends"}]
    end)

    assert [%List{title: "Friends"}] = List.lists(@conn)
  end

  test "returns a single list" do
    expect(Hunter.ApiMock, :list, fn %Hunter.Client{}, 12_249 ->
      %List{id: "12249", title: "Friends"}
    end)

    assert %List{id: "12249"} = List.list(@conn, 12_249)
  end

  test "creates a list" do
    expect(Hunter.ApiMock, :create_list, fn %Hunter.Client{}, "Friends", opts ->
      %List{id: "12249", title: "Friends", replies_policy: opts[:replies_policy]}
    end)

    assert %List{title: "Friends", replies_policy: "followed"} =
             List.create_list(@conn, "Friends", replies_policy: "followed")
  end

  test "updates a list" do
    expect(Hunter.ApiMock, :update_list, fn %Hunter.Client{}, 12_249, opts ->
      %List{id: "12249", title: opts[:title], exclusive: opts[:exclusive]}
    end)

    assert %List{title: "Close friends", exclusive: true} =
             List.update_list(@conn, 12_249, title: "Close friends", exclusive: true)
  end

  test "destroys a list" do
    expect(Hunter.ApiMock, :destroy_list, fn %Hunter.Client{}, 12_249 -> true end)

    assert List.destroy_list(@conn, 12_249)
  end

  test "returns accounts in a list" do
    expect(Hunter.ApiMock, :list_accounts, fn %Hunter.Client{}, 12_249, _opts ->
      [%Hunter.Account{id: "8039", username: "kadaba"}]
    end)

    assert [%Hunter.Account{username: "kadaba"}] = List.list_accounts(@conn, 12_249)
  end

  test "adds accounts to a list" do
    expect(Hunter.ApiMock, :add_accounts_to_list, fn %Hunter.Client{}, 12_249, [8039] ->
      true
    end)

    assert List.add_accounts_to_list(@conn, 12_249, [8039])
  end

  test "removes accounts from a list" do
    expect(Hunter.ApiMock, :remove_accounts_from_list, fn %Hunter.Client{}, 12_249, [8039] ->
      true
    end)

    assert List.remove_accounts_from_list(@conn, 12_249, [8039])
  end

  test "returns lists containing a given account" do
    expect(Hunter.ApiMock, :account_lists, fn %Hunter.Client{}, 8039 ->
      [%List{id: "12249", title: "Friends"}]
    end)

    assert [%List{title: "Friends"}] = List.account_lists(@conn, 8039)
  end
end
