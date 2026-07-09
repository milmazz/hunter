defmodule Hunter.PollTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Poll

  @conn Hunter.new(base_url: "https://mastodon.example", access_token: "123456")

  test "returns a poll with decoded options" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/polls/34830"
      respond_with_fixture(conn, "poll")
    end)

    poll = Poll.poll(@conn, 34_830)

    assert %Poll{id: "34830", expired: false, votes_count: 10} = poll

    assert [
             %Hunter.Poll.Option{title: "accept", votes_count: 6},
             %Hunter.Poll.Option{title: "deny", votes_count: 4}
           ] = poll.options
  end

  test "votes on poll options with a JSON body" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/polls/34830/votes"
      assert %{"choices" => [1]} = read_json_body!(conn)
      respond_with_fixture(conn, "poll")
    end)

    assert %Poll{voted: true, own_votes: [1]} = Poll.vote(@conn, 34_830, [1])
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Poll.poll(@conn, 0) end
  end
end
