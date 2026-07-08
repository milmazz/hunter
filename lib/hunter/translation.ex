defmodule Hunter.Translation do
  @moduledoc """
  Translation entity

  The translation of a status into some language, as returned by the
  status translate endpoint

  ## Fields

    * `content` - HTML-encoded translated content of the status
    * `spoiler_text` - translated spoiler warning of the status
    * `poll` - translated poll options, a map with `id` and `options` keys,
      if the status has a poll
    * `media_attachments` - translated media descriptions, a list of maps
      with `id` and `description` keys
    * `language` - the language of the source text, as provided by the
      translation provider
    * `detected_source_language` - the language detected in the source text
    * `provider` - the service that provided the machine translation

  """

  @type t :: %__MODULE__{
          content: String.t(),
          spoiler_text: String.t(),
          poll: map | nil,
          media_attachments: [map],
          language: String.t(),
          detected_source_language: String.t(),
          provider: String.t()
        }

  @derive [Poison.Encoder]
  defstruct [
    :content,
    :spoiler_text,
    :poll,
    :media_attachments,
    :language,
    :detected_source_language,
    :provider
  ]
end
