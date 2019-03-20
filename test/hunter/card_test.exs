defmodule Hunter.CardTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Card

  setup :verify_on_exit!

  test "verify a card associated with a status" do
    expect(Hunter.ApiMock, :card_by_status, fn _conn, _id ->
      %Card{title: "milmazz/hunter"}
    end)

    conn = Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")
    assert %Card{title: "milmazz/hunter"} = Card.card_by_status(conn, 118_635)
  end
end
