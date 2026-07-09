defmodule Hunter.ReportTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Report

  @conn Hunter.new(base_url: "https://mastodon.example", access_token: "123456")

  test "reports an account with a JSON body" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/reports"
      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer 123456"]

      assert %{
               "account_id" => 8039,
               "status_ids" => [153_452],
               "comment" => "spam"
             } = read_json_body!(conn)

      respond_with_fixture(conn, "report")
    end)

    assert %Report{id: "48914", action_taken: false} =
             Hunter.report(@conn, 8039, [153_452], "spam")
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Hunter.report(@conn, 0, [], "spam") end
  end
end
