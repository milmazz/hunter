defmodule Hunter.StatusTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Status

  @conn Hunter.Client.new(base_url: "https://mastodon.example", access_token: "123456")

  test "home timeline sends query params and returns statuses" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/timelines/home"
      assert conn.query_string == "limit=1"
      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer 123456"]
      respond_with_fixture(conn, "status", wrap: :list)
    end)

    assert [%Status{visibility: "public"}] = Status.home_timeline(@conn, limit: 1)
  end

  test "public timeline sends the local flag" do
    stub_request(fn conn ->
      assert conn.request_path == "/api/v1/timelines/public"
      assert conn.query_string =~ "local=true"
      respond_with_fixture(conn, "status", wrap: :list)
    end)

    assert [%Status{}] = Status.public_timeline(@conn, limit: 1, local: true)
  end

  test "hashtag timeline interpolates the tag" do
    stub_request(fn conn ->
      assert conn.request_path == "/api/v1/timelines/tag/elixir"
      respond_with_fixture(conn, "status", wrap: :list)
    end)

    assert [%Status{}] = Status.hashtag_timeline(@conn, "elixir")
  end

  test "list timeline interpolates the list id" do
    stub_request(fn conn ->
      assert conn.request_path == "/api/v1/timelines/list/12249"
      respond_with_fixture(conn, "status", wrap: :list)
    end)

    assert [%Status{}] = Status.list_timeline(@conn, 12_249)
  end

  test "creates a status with a JSON body" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/statuses"
      assert %{"status" => "hello", "visibility" => "unlisted"} = read_json_body!(conn)
      respond_with_fixture(conn, "status")
    end)

    assert %Status{} = Status.create_status(@conn, "hello", visibility: "unlisted")
  end

  test "creating a status with an idempotency key sends the header" do
    stub_request(fn conn ->
      assert Plug.Conn.get_req_header(conn, "idempotency-key") == ["abc-123"]
      body = read_json_body!(conn)
      refute Map.has_key?(body, "idempotency_key")
      respond_with_fixture(conn, "status")
    end)

    assert %Status{} = Status.create_status(@conn, "hello", idempotency_key: "abc-123")
  end

  test "creating a scheduled status decodes a ScheduledStatus" do
    stub_request(fn conn ->
      assert %{"scheduled_at" => "2026-07-20T13:00:00.000Z"} = read_json_body!(conn)
      respond_with_fixture(conn, "scheduled_status")
    end)

    assert %Hunter.ScheduledStatus{id: "3221"} =
             Status.create_status(@conn, "later", scheduled_at: "2026-07-20T13:00:00.000Z")
  end

  test "returns a single status with nested entities" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/statuses/153452"
      respond_with_fixture(conn, "status")
    end)

    status = Status.status(@conn, 153_452)

    assert %Status{id: "103270115826048975"} = status
    assert %Hunter.Account{username: "milmazz"} = status.account
    assert %Hunter.Poll{id: "34830"} = status.poll
  end

  test "returns multiple statuses by id" do
    stub_request(fn conn ->
      assert conn.request_path == "/api/v1/statuses"
      assert conn.query_string == URI.encode_query([{"id[]", "1"}, {"id[]", "2"}])
      respond_with_fixture(conn, "status", wrap: :list)
    end)

    assert [%Status{}] = Status.statuses_by_ids(@conn, [1, 2])
  end

  test "destroys a status" do
    stub_request(fn conn ->
      assert conn.method == "DELETE"
      assert conn.request_path == "/api/v1/statuses/153452"
      respond_with(conn, %{})
    end)

    assert Status.destroy_status(@conn, 153_452)
  end

  test "edits a status" do
    stub_request(fn conn ->
      assert conn.method == "PUT"
      assert conn.request_path == "/api/v1/statuses/153452"
      assert %{"status" => "hello again", "language" => "en"} = read_json_body!(conn)
      respond_with_fixture(conn, "status")
    end)

    assert %Status{} = Status.edit_status(@conn, 153_452, "hello again", language: "en")
  end

  test "returns the edit history of a status" do
    stub_request(fn conn ->
      assert conn.request_path == "/api/v1/statuses/153452/history"
      respond_with_fixture(conn, "status_edit", wrap: :list)
    end)

    assert [%Hunter.StatusEdit{sensitive: false}] = Status.status_history(@conn, 153_452)
  end

  test "returns the source of a status" do
    stub_request(fn conn ->
      assert conn.request_path == "/api/v1/statuses/153452/source"
      respond_with_fixture(conn, "status_source")
    end)

    assert %Hunter.StatusSource{text: "Testing #elixir with @kadaba"} =
             Status.status_source(@conn, 153_452)
  end

  for {action, function} <- [
        reblog: :reblog,
        unreblog: :unreblog,
        favourite: :favourite,
        unfavourite: :unfavourite,
        bookmark: :bookmark,
        unbookmark: :unbookmark,
        pin: :pin,
        unpin: :unpin,
        mute: :mute_conversation,
        unmute: :unmute_conversation
      ] do
    test "#{function} posts to /statuses/:id/#{action}" do
      stub_request(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/api/v1/statuses/153452/#{unquote(action)}"
        respond_with_fixture(conn, "status")
      end)

      assert %Status{} = apply(Status, unquote(function), [@conn, 153_452])
    end
  end

  test "returns favourited statuses" do
    stub_request(fn conn ->
      assert conn.request_path == "/api/v1/favourites"
      respond_with_fixture(conn, "status", wrap: :list)
    end)

    assert [%Status{}] = Status.favourites(@conn)
  end

  test "returns bookmarked statuses" do
    stub_request(fn conn ->
      assert conn.request_path == "/api/v1/bookmarks"
      respond_with_fixture(conn, "status", wrap: :list)
    end)

    assert [%Status{}] = Status.bookmarks(@conn)
  end

  test "returns statuses from an account with query params" do
    stub_request(fn conn ->
      assert conn.request_path == "/api/v1/accounts/23634/statuses"
      assert conn.query_string == "limit=1"
      respond_with_fixture(conn, "status", wrap: :list)
    end)

    assert [%Status{}] = Status.statuses(@conn, 23_634, limit: 1)
  end

  test "translates a status" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/statuses/153452/translate"
      assert %{"lang" => "es"} = read_json_body!(conn)
      respond_with_fixture(conn, "translation")
    end)

    assert %Hunter.Translation{language: "es"} =
             Status.translate_status(@conn, 153_452, lang: "es")
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Status.status(@conn, 0) end
  end
end
