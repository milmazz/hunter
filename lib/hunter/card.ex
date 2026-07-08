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
    * `blurhash` - hash computed by the BlurHash algorithm, for generating
      colorful preview thumbnails when media has not been downloaded yet
    * `embed_url` - used for photo embeds instead of custom `html`
    * `authors` - list of `Hunter.Card.Author`, fediverse authors of the resource
    * `published_at` - publication date as a UNIX timestamp, only present on
      trending links
    * `history` - usage statistics, only present on trending links

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
          height: non_neg_integer,
          blurhash: String.t() | nil,
          embed_url: String.t() | nil,
          authors: [Hunter.Card.Author.t()] | nil,
          published_at: String.t() | nil,
          history: [map] | nil
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
    :height,
    :blurhash,
    :embed_url,
    :authors,
    :published_at,
    :history
  ]
end
