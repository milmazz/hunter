defmodule Hunter.StatusTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Status

  @conn Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")

  setup :verify_on_exit!

  test "home timeline should return a collection of statuses" do
    expect(Hunter.ApiMock, :home_timeline, fn _conn, _opts ->
      [%Hunter.Status{}]
    end)

    assert [_timeline | []] = Status.home_timeline(@conn, limit: 1)
  end

  test "public time should return a collection of statuses" do
    expect(Hunter.ApiMock, :public_timeline, fn _conn, _opts ->
      [%Hunter.Status{}]
    end)

    assert [_timeline | []] = Status.public_timeline(@conn, limit: 1, local: true)
  end

  test "should allow to create new status" do
    expect(Hunter.ApiMock, :create_status, fn _conn, status, _opts ->
      %Hunter.Status{content: status}
    end)

    assert %Hunter.Status{content: "hello"} = Status.create_status(@conn, "hello")
  end

  test "returns a single status" do
    expect(Hunter.ApiMock, :status, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452"}
    end)

    assert %Status{id: "153452"} = Status.status(@conn, 153_452)
  end

  test "destroys a status" do
    expect(Hunter.ApiMock, :destroy_status, fn %Hunter.Client{}, 153_452 -> true end)

    assert Status.destroy_status(@conn, 153_452)
  end

  test "reblogs and unreblogs a status" do
    expect(Hunter.ApiMock, :reblog, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452", reblogged: true}
    end)

    expect(Hunter.ApiMock, :unreblog, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452", reblogged: false}
    end)

    assert %Status{reblogged: true} = Status.reblog(@conn, 153_452)
    assert %Status{reblogged: false} = Status.unreblog(@conn, 153_452)
  end

  test "favourites and unfavourites a status" do
    expect(Hunter.ApiMock, :favourite, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452", favourited: true}
    end)

    expect(Hunter.ApiMock, :unfavourite, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452", favourited: false}
    end)

    assert %Status{favourited: true} = Status.favourite(@conn, 153_452)
    assert %Status{favourited: false} = Status.unfavourite(@conn, 153_452)
  end

  test "returns authenticated user's favourites" do
    expect(Hunter.ApiMock, :favourites, fn %Hunter.Client{}, [] ->
      [%Status{id: "153452"}]
    end)

    assert [%Status{id: "153452"}] = Status.favourites(@conn)
  end

  test "returns statuses from an account" do
    # Status.statuses/3 converts options with Map.new/1 before delegating
    expect(Hunter.ApiMock, :statuses, fn %Hunter.Client{}, 23_634, %{} ->
      [%Status{id: "153452"}]
    end)

    assert [%Status{}] = Status.statuses(@conn, 23_634)
  end

  test "returns a hashtag timeline" do
    expect(Hunter.ApiMock, :hashtag_timeline, fn %Hunter.Client{}, "elixir", %{} ->
      [%Status{id: "153452"}]
    end)

    assert [%Status{}] = Status.hashtag_timeline(@conn, "elixir")
  end

  test "propagates API errors" do
    expect(Hunter.ApiMock, :status, fn %Hunter.Client{}, _id ->
      raise Hunter.Error, reason: "Record not found"
    end)

    assert_raise Hunter.Error, fn -> Status.status(@conn, 0) end
  end
end
