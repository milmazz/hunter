defmodule Hunter.DomainTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Domain

  @conn Hunter.new(base_url: "https://mastodon.example", access_token: "123456")

  test "returns blocked domains as a plain list" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/domain_blocks"
      respond_with(conn, ["blocked.example"])
    end)

    assert Domain.blocked_domains(@conn) == ["blocked.example"]
  end

  test "blocks a domain with a JSON body" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/domain_blocks"
      assert %{"domain" => "blocked.example"} = read_json_body!(conn)
      respond_with(conn, %{})
    end)

    assert Domain.block_domain(@conn, "blocked.example") == true
  end

  test "unblocks a domain with a query param" do
    stub_request(fn conn ->
      assert conn.method == "DELETE"
      assert conn.request_path == "/api/v1/domain_blocks"
      assert conn.query_string == "domain=blocked.example"
      respond_with(conn, %{})
    end)

    assert Domain.unblock_domain(@conn, "blocked.example") == true
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Domain.blocked_domains(@conn) end
  end
end
