defmodule Hunter.Attribute do
  @moduledoc """
  Attribute entity

  This module defines a `Hunter.Attribute` struct and the main functions
  for working with Attributes.

  ## Fields

    * `id` - ID of the attachment
    * `type` - One of: "image", "video", "gifv"
    * `url` - URL of the locally hosted version of the image
    * `remote_url` - For remote images, the remote URL of the original image
    * `preview_url` - URL of the preview image
    * `text_url` - Shorter URL for the image, for insertion into text (only present on local images)

  """
  @type t :: %__MODULE__{
    id: non_neg_integer,
    type: String.t,
    url: URI.t,
    remote_url: URI.t,
    preview_url: URI.t,
    text_url: URI.t
  }

  @derive [Poison.Encoder]
  defstruct [:id, :type, :url, :remote_url, :preview_url, :text_url]
end
