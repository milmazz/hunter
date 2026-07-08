defmodule Hunter.PollTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Poll

  @conn Hunter.Client.new(base_url: "https://example.com", access_token: "123456")

  setup :verify_on_exit!

  test "returns a poll" do
    expect(Hunter.ApiMock, :poll, fn %Hunter.Client{}, 34_830 ->
      %Poll{id: "34830", expired: false}
    end)

    assert %Poll{id: "34830"} = Poll.poll(@conn, 34_830)
  end

  test "votes on poll options" do
    expect(Hunter.ApiMock, :vote, fn %Hunter.Client{}, 34_830, [1] ->
      %Poll{id: "34830", voted: true, own_votes: [1]}
    end)

    assert %Poll{voted: true, own_votes: [1]} = Poll.vote(@conn, 34_830, [1])
  end
end
