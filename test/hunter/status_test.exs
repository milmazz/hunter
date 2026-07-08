defmodule Hunter.StatusTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Status

  @conn Hunter.Client.new(base_url: "https://example.com", access_token: "123456")

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

  test "edits a status" do
    expect(Hunter.ApiMock, :edit_status, fn %Hunter.Client{}, 153_452, "hello again", opts ->
      %Status{id: "153452", content: "hello again", language: opts[:language]}
    end)

    assert %Status{content: "hello again", language: "en"} =
             Status.edit_status(@conn, 153_452, "hello again", language: "en")
  end

  test "returns the edit history of a status" do
    expect(Hunter.ApiMock, :status_history, fn %Hunter.Client{}, 153_452 ->
      [%Hunter.StatusEdit{content: "<p>hello again</p>"}]
    end)

    assert [%Hunter.StatusEdit{}] = Status.status_history(@conn, 153_452)
  end

  test "returns the source of a status" do
    expect(Hunter.ApiMock, :status_source, fn %Hunter.Client{}, 153_452 ->
      %Hunter.StatusSource{id: "153452", text: "hello again"}
    end)

    assert %Hunter.StatusSource{text: "hello again"} = Status.status_source(@conn, 153_452)
  end

  test "bookmarks and unbookmarks a status" do
    expect(Hunter.ApiMock, :bookmark, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452", bookmarked: true}
    end)

    expect(Hunter.ApiMock, :unbookmark, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452", bookmarked: false}
    end)

    assert %Status{bookmarked: true} = Status.bookmark(@conn, 153_452)
    assert %Status{bookmarked: false} = Status.unbookmark(@conn, 153_452)
  end

  test "returns bookmarked statuses" do
    expect(Hunter.ApiMock, :bookmarks, fn %Hunter.Client{}, _opts ->
      [%Status{id: "153452", bookmarked: true}]
    end)

    assert [%Status{bookmarked: true}] = Status.bookmarks(@conn)
  end

  test "pins and unpins a status" do
    expect(Hunter.ApiMock, :pin, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452", pinned: true}
    end)

    expect(Hunter.ApiMock, :unpin, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452", pinned: false}
    end)

    assert %Status{pinned: true} = Status.pin(@conn, 153_452)
    assert %Status{pinned: false} = Status.unpin(@conn, 153_452)
  end

  test "mutes and unmutes a conversation" do
    expect(Hunter.ApiMock, :mute_conversation, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452", muted: true}
    end)

    expect(Hunter.ApiMock, :unmute_conversation, fn %Hunter.Client{}, 153_452 ->
      %Status{id: "153452", muted: false}
    end)

    assert %Status{muted: true} = Status.mute_conversation(@conn, 153_452)
    assert %Status{muted: false} = Status.unmute_conversation(@conn, 153_452)
  end

  test "translates a status" do
    expect(Hunter.ApiMock, :translate_status, fn %Hunter.Client{}, 153_452, [lang: "es"] ->
      %Hunter.Translation{content: "<p>hola</p>", language: "es"}
    end)

    assert %Hunter.Translation{language: "es"} =
             Status.translate_status(@conn, 153_452, lang: "es")
  end

  test "returns multiple statuses by id" do
    expect(Hunter.ApiMock, :statuses_by_ids, fn %Hunter.Client{}, [153_452, 153_453] ->
      [%Status{id: "153452"}, %Status{id: "153453"}]
    end)

    assert [%Status{}, %Status{}] = Status.statuses_by_ids(@conn, [153_452, 153_453])
  end
end
