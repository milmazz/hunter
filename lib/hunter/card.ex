defmodule Hunter.Card do
  @moduledoc """
  Card entity

  This module defines a `Hunter.Card` struct and the main functions
  for working with Cards

  ## Fields

    * `url`- The url associated with the card
    * `title` - The title of the card
    * `description` - The card description
    * `image` - The image associated with the card, if any

  """
  @hunter_api Hunter.Config.hunter_api()

  @type t :: %__MODULE__{
    url: String.t,
    title: String.t,
    description: String.t,
    image: String.t
  }

  @derive [Poison.Encoder]
  defstruct [:url, :title, :description, :image]

  @doc """
  Retrieve a card associated with a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status id

  ## Examples

      iex> conn = Hunter.new([base_url: "https://social.lou.lt", bearer_token: "123456"])
      %Hunter.Client{base_url: "https://social.lou.lt", bearer_token: "123456"}
      iex> Hunter.Card.card_by_status(conn, 118_635)
      %Hunter.Card{description: "hunter - A Elixir client for Mastodon, a GNU Social compatible micro-blogging service",
                image: "https://social.lou.lt/system/preview_cards/images/000/000/378/original/34700?1491626499",
                title: "milmazz/hunter", url: "https://github.com/milmazz/hunter"}

  """
  @spec card_by_status(Hunter.Client.t, non_neg_integer) :: Hunter.Card.t
  def card_by_status(conn, id) do
    @hunter_api.card_by_status(conn, id)
  end
end
