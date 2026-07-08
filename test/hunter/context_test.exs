defmodule Hunter.ContextTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Context

  @conn Hunter.Client.new(base_url: "https://mastodon.example", access_token: "123456")

  test "returns the context of a status" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/statuses/153452/context"
      respond_with_fixture(conn, "context")
    end)

    context = Context.status_context(@conn, 153_452)

    assert %Context{} = context
    assert [%Hunter.Status{id: "103270115826048970"}] = context.ancestors
    assert [%Hunter.Status{id: "103270115826048999"}] = context.descendants
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Context.status_context(@conn, 0) end
  end
end
