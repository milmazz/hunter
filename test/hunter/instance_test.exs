defmodule Hunter.InstanceTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Instance

  @conn Hunter.new(base_url: "https://mastodon.example", access_token: "123456")

  test "returns instance information with nested entities" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v2/instance"
      respond_with_fixture(conn, "instance")
    end)

    instance = Hunter.instance_info(@conn)

    assert %Instance{domain: "mastodon.example", version: "4.3.8"} = instance
    assert instance.contact["email"] == "admin@mastodon.example"
    assert [%Hunter.Rule{id: "1", text: "Be excellent to each other"}] = instance.rules
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Hunter.instance_info(@conn) end
  end
end
