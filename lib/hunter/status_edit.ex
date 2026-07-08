defmodule Hunter.StatusEdit do
  @moduledoc """
  StatusEdit entity

  A revision of a `Hunter.Status`, as returned by the status edit history
  endpoint

  ## Fields

    * `content` - the content of the status at this revision, as HTML
    * `spoiler_text` - the content of the subject/spoiler at this revision,
      as HTML
    * `sensitive` - whether the status was marked sensitive at this revision
    * `created_at` - when the revision was published
    * `account` - the `Hunter.Account` that published the status
    * `poll` - the poll options at this revision, a map with an `options`
      key (only when the status has a poll)
    * `media_attachments` - list of `Hunter.Attachment` at this revision
    * `emojis` - list of `Hunter.Emoji`, custom emoji used in the revision

  """

  @type t :: %__MODULE__{
          content: String.t(),
          spoiler_text: String.t(),
          sensitive: boolean,
          created_at: String.t(),
          account: Hunter.Account.t(),
          poll: map | nil,
          media_attachments: [Hunter.Attachment.t()],
          emojis: [Hunter.Emoji.t()]
        }

  @derive [Poison.Encoder]
  defstruct [
    :content,
    :spoiler_text,
    :sensitive,
    :created_at,
    :account,
    :poll,
    :media_attachments,
    :emojis
  ]
end
