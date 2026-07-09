defmodule Hunter.ResultTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Result

  @conn Hunter.new(base_url: "https://mastodon.example", access_token: "123456")

  test "searches for content with query params" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v2/search"
      assert conn.query_string =~ "q=elixir"
      assert conn.query_string =~ "resolve=true"
      respond_with_fixture(conn, "result")
    end)

    result = Hunter.search(@conn, "elixir", resolve: true)

    assert %Result{} = result
    assert [%Hunter.Account{username: "milmazz"}] = result.accounts
    assert [%Hunter.Status{visibility: "public"}] = result.statuses
    assert [%Hunter.Tag{name: "elixir"}] = result.hashtags
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Hunter.search(@conn, "elixir") end
  end
end
