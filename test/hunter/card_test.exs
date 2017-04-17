defmodule Hunter.CardTest do
  use ExUnit.Case, async: true

  alias Hunter.Card

  setup do
    [conn: Hunter.Client.new([base_url: "https://example.com", bearer_token: "123456"])]
  end

  test "verify a card associated with a status", %{conn: conn} do
    assert %Card{title: "milmazz/hunter"} = Card.card_by_status(conn, 118635)
  end
end
