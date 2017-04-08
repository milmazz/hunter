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
  @type t :: %__MODULE__{
    url: URI.t,
    title: String.t,
    description: String.t,
    image: String.t
  }

  @derive [Poison.Encoder]
  defstruct [:url, :title, :description, :image]

end


