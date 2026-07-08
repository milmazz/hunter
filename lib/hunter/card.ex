defmodule Hunter.Card do
  @moduledoc """
  Card entity

  This module defines a `Hunter.Card` struct representing a preview card
  for links included in a status, embedded in `Hunter.Status`

  ## Fields

    * `url`- the url associated with the card
    * `title` - the title of the card
    * `description` - the card description
    * `image` - the image associated with the card, if any
    * `type` - `link`, `photo`, `video`, or `rich`
    * `author_name` - name of the author/owner of the resource
    * `author_url` - URL for the author/owner of the resource
    * `provider_name` - name of the resource provider
    * `provider_url` - url of the resource provider
    * `html` - HTML required to display the resource
    * `width` - width in pixels
    * `height` - height in pixels

  """

  @type t :: %__MODULE__{
          url: String.t(),
          title: String.t(),
          description: String.t(),
          image: String.t(),
          type: String.t(),
          author_name: String.t(),
          author_url: String.t(),
          provider_name: String.t(),
          provider_url: String.t(),
          html: String.t(),
          width: non_neg_integer,
          height: non_neg_integer
        }

  @derive [Poison.Encoder]
  defstruct [
    :url,
    :title,
    :description,
    :image,
    :type,
    :author_name,
    :author_url,
    :provider_name,
    :provider_url,
    :html,
    :width,
    :height
  ]
end
