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
  @hunter_api Application.get_env(:hunter, :hunter_api)

  @type t :: %__MODULE__{
    url: URI.t,
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

  """
  @spec card_by_status(Hunter.Client.t, non_neg_integer) :: Hunter.Card.t
  def card_by_status(conn, id) do
    @hunter_api.card_by_status(conn, id)
  end
end
