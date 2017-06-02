defmodule Hunter.Attachment do
  @moduledoc """
  Attachment entity

  This module defines a `Hunter.Attachment` struct and the main functions
  for working with Attachments.

  ## Fields

    * `id` - ID of the attachment
    * `type` - One of: "image", "video", "gifv"
    * `url` - URL of the locally hosted version of the image
    * `remote_url` - For remote images, the remote URL of the original image
    * `preview_url` - URL of the preview image
    * `text_url` - Shorter URL for the image, for insertion into text (only present on local images)
    * `meta` - Specifies `width`, `height`, `size` (width x height), `aspect`

  """
  @hunter_api Hunter.Config.hunter_api()

  @type t :: %__MODULE__{
    id: non_neg_integer,
    type: String.t,
    url: String.t,
    remote_url: String.t,
    preview_url: String.t,
    text_url: String.t,
    meta: String.t
  }

  @derive [Poison.Encoder]
  defstruct [:id, :type, :url, :remote_url, :preview_url, :text_url, :meta]

  @doc """
  Upload a media attachment

  ## Parameters

    * `conn` - connection credentials
    * `file` - media to be uploaded

  """
  @spec upload_media(Hunter.Client.t, Path.t) :: Hunter.Attachment.t
  def upload_media(conn, file) do
    @hunter_api.upload_media(conn, file)
  end
end
