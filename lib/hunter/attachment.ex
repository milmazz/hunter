defmodule Hunter.Attachment do
  @moduledoc """
  Attachment entity

  This module defines a `Hunter.Attachment` struct.

  ## Fields

    * `id` - ID of the attachment
    * `type` - One of: "image", "video", "gifv", "audio", "unknown"
    * `url` - URL of the locally hosted version of the image
    * `remote_url` - For remote images, the remote URL of the original image
    * `preview_url` - URL of the preview image
    * `text_url` - Shorter URL for the image, for insertion into text (only
      present on local images)
    * `meta` - May contain subtress `small` and `original`. Images may contain:
      `width`, `height`, `size`, `aspect`, while videos (including `gifv`) may
      contain: `width`, `height`, `frame_rate`, `duration`, and `bitrate`.
    * `preview_remote_url` - for remote images, the remote URL of the preview image
    * `description` - attachment description
    * `blurhash` - hash computed by the BlurHash algorithm, for generating
      colorful preview thumbnails when media has not been downloaded yet

  **Note**: When the type is "unknown", it is likely only `remote_url` is
  available and local `url` is missing

  """

  @type t :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          url: String.t(),
          remote_url: String.t(),
          preview_url: String.t(),
          preview_remote_url: String.t() | nil,
          text_url: String.t(),
          meta: map | nil,
          description: String.t(),
          blurhash: String.t() | nil
        }

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :type,
    :url,
    :remote_url,
    :preview_url,
    :preview_remote_url,
    :text_url,
    :meta,
    :description,
    :blurhash
  ]
end
