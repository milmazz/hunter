defmodule Hunter.Announcement.Reaction do
  @moduledoc """
  Announcement reaction entity

  An emoji reaction attached to a `Hunter.Announcement`

  ## Fields

    * `name` - the emoji used for the reaction, either a unicode emoji or
      a custom emoji's shortcode
    * `count` - the total number of users who have added this reaction
    * `me` - whether the authenticated user added this reaction (only with
      user token)
    * `url` - URL of the custom emoji, if the reaction is a custom emoji
    * `static_url` - static URL of the custom emoji, if the reaction is a
      custom emoji

  """

  @type t :: %__MODULE__{
          name: String.t(),
          count: non_neg_integer,
          me: boolean | nil,
          url: String.t() | nil,
          static_url: String.t() | nil
        }

  @derive [Poison.Encoder]
  defstruct [:name, :count, :me, :url, :static_url]
end
