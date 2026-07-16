defmodule Hunter.FilterTest do
  use Hunter.ReqCase, async: true

  alias Hunter.{Filter, FilterKeyword, FilterStatus}

  @conn Hunter.new(base_url: "https://mastodon.example", access_token: "123456")

  test "returns all filters the user owns" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v2/filters"
      respond_with_fixture(conn, "filter", wrap: :list)
    end)

    assert [%Filter{id: "19972", title: "Test filter", filter_action: "warn"}] =
             Hunter.filters(@conn)
  end

  test "returns a single filter with nested keywords and statuses" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v2/filters/19972"
      respond_with_fixture(conn, "filter")
    end)

    assert %Filter{
             id: "19972",
             context: ["home"],
             keywords: [%FilterKeyword{keyword: "bad word"}],
             statuses: [%FilterStatus{status_id: "109031743575371913"}]
           } = Hunter.filter(@conn, 19_972)
  end

  test "creates a filter with a JSON body" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v2/filters"

      assert %{
               "title" => "Test filter",
               "context" => ["home"],
               "filter_action" => "blur",
               "keywords_attributes" => [%{"keyword" => "bad word", "whole_word" => false}]
             } = read_json_body!(conn)

      respond_with_fixture(conn, "filter")
    end)

    assert %Filter{id: "19972", title: "Test filter"} =
             Hunter.create_filter(@conn, "Test filter", ["home"],
               filter_action: "blur",
               keywords_attributes: [%{keyword: "bad word", whole_word: false}]
             )
  end

  test "updates a filter" do
    stub_request(fn conn ->
      assert conn.method == "PUT"
      assert conn.request_path == "/api/v2/filters/19972"
      assert %{"title" => "Updated filter", "expires_in" => 86_400} = read_json_body!(conn)
      respond_with_fixture(conn, "filter")
    end)

    assert %Filter{id: "19972"} =
             Hunter.update_filter(@conn, 19_972, title: "Updated filter", expires_in: 86_400)
  end

  test "destroys a filter" do
    stub_request(fn conn ->
      assert conn.method == "DELETE"
      assert conn.request_path == "/api/v2/filters/19972"
      respond_with(conn, %{})
    end)

    assert Hunter.destroy_filter(@conn, 19_972) == true
  end

  test "returns the keywords of a filter" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v2/filters/19972/keywords"
      respond_with_fixture(conn, "filter_keyword", wrap: :list)
    end)

    assert [%FilterKeyword{id: "1197", keyword: "bad word"}] =
             Hunter.filter_keywords(@conn, 19_972)
  end

  test "adds a keyword to a filter with a JSON body" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v2/filters/19972/keywords"
      assert %{"keyword" => "bad word", "whole_word" => false} = read_json_body!(conn)
      respond_with_fixture(conn, "filter_keyword")
    end)

    assert %FilterKeyword{id: "1197"} =
             Hunter.add_keyword_to_filter(@conn, 19_972, "bad word", whole_word: false)
  end

  test "returns a single filter keyword" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v2/filters/keywords/1197"
      respond_with_fixture(conn, "filter_keyword")
    end)

    assert %FilterKeyword{id: "1197", whole_word: false} = Hunter.filter_keyword(@conn, 1197)
  end

  test "updates a filter keyword" do
    stub_request(fn conn ->
      assert conn.method == "PUT"
      assert conn.request_path == "/api/v2/filters/keywords/1197"
      assert %{"keyword" => "worse word", "whole_word" => true} = read_json_body!(conn)
      respond_with_fixture(conn, "filter_keyword")
    end)

    assert %FilterKeyword{id: "1197"} =
             Hunter.update_filter_keyword(@conn, 1197, keyword: "worse word", whole_word: true)
  end

  test "destroys a filter keyword" do
    stub_request(fn conn ->
      assert conn.method == "DELETE"
      assert conn.request_path == "/api/v2/filters/keywords/1197"
      respond_with(conn, %{})
    end)

    assert Hunter.destroy_filter_keyword(@conn, 1197) == true
  end

  test "returns the status filters of a filter" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v2/filters/19972/statuses"
      respond_with_fixture(conn, "filter_status", wrap: :list)
    end)

    assert [%FilterStatus{id: "1", status_id: "109031743575371913"}] =
             Hunter.filter_statuses(@conn, 19_972)
  end

  test "adds a status to a filter with a JSON body" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v2/filters/19972/statuses"
      assert %{"status_id" => "109031743575371913"} = read_json_body!(conn)
      respond_with_fixture(conn, "filter_status")
    end)

    assert %FilterStatus{id: "1"} =
             Hunter.add_status_to_filter(@conn, 19_972, "109031743575371913")
  end

  test "returns a single status filter" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v2/filters/statuses/1"
      respond_with_fixture(conn, "filter_status")
    end)

    assert %FilterStatus{id: "1", status_id: "109031743575371913"} =
             Hunter.filter_status(@conn, 1)
  end

  test "destroys a status filter" do
    stub_request(fn conn ->
      assert conn.method == "DELETE"
      assert conn.request_path == "/api/v2/filters/statuses/1"
      respond_with(conn, %{})
    end)

    assert Hunter.destroy_filter_status(@conn, 1) == true
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Hunter.filter(@conn, 0) end
  end
end
