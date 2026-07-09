defmodule Hunter.RelationshipTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Relationship

  @conn Hunter.Client.new(base_url: "https://mastodon.example", access_token: "123456")

  test "returns relationships to other accounts with id[] params" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/accounts/relationships"
      assert conn.query_string == URI.encode_query([{"id[]", "8039"}, {"id[]", "8040"}])
      respond_with_fixture(conn, "relationship", wrap: :list)
    end)

    assert [%Relationship{id: "8039", following: true, note: "college friend"}] =
             Relationship.relationships(@conn, [8039, 8040])
  end

  for {function, action} <- [
        follow: "follow",
        unfollow: "unfollow",
        block: "block",
        unblock: "unblock",
        mute: "mute",
        unmute: "unmute"
      ] do
    test "#{function} posts to /accounts/:id/#{action}" do
      stub_request(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/api/v1/accounts/8039/#{unquote(action)}"
        respond_with_fixture(conn, "relationship")
      end)

      assert %Relationship{id: "8039"} = apply(Relationship, unquote(function), [@conn, 8039])
    end
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Relationship.follow(@conn, 0) end
  end
end
