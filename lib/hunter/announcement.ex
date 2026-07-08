defmodule Hunter.Announcement do
  @moduledoc """
  Announcement entity

  An announcement set by an administrator

  ## Fields

    * `id` - the ID of the announcement
    * `content` - the text of the announcement, as HTML
    * `starts_at` - when the announcement starts being active, if time-limited
    * `ends_at` - when the announcement stops being active, if time-limited
    * `all_day` - whether the announcement should start and end on dates only
      instead of datetimes
    * `published_at` - when the announcement was published
    * `updated_at` - when the announcement was last updated
    * `read` - whether the announcement has been read by the authenticated
      user (only with user token)
    * `mentions` - accounts mentioned in the announcement text, list of maps
      with `id`, `username`, `url` and `acct` keys
    * `statuses` - statuses linked in the announcement text, list of maps
      with `id` and `url` keys
    * `tags` - list of `Hunter.Tag` used in the announcement text
    * `emojis` - list of `Hunter.Emoji`, custom emoji used in the
      announcement text
    * `reactions` - list of `Hunter.Announcement.Reaction`, emoji reactions
      attached to the announcement

  """

  @type t :: %__MODULE__{
          id: String.t(),
          content: String.t(),
          starts_at: String.t() | nil,
          ends_at: String.t() | nil,
          all_day: boolean,
          published_at: String.t(),
          updated_at: String.t(),
          read: boolean | nil,
          mentions: [map],
          statuses: [map],
          tags: [Hunter.Tag.t()],
          emojis: [Hunter.Emoji.t()],
          reactions: [Hunter.Announcement.Reaction.t()]
        }

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :content,
    :starts_at,
    :ends_at,
    :all_day,
    :published_at,
    :updated_at,
    :read,
    :mentions,
    :statuses,
    :tags,
    :emojis,
    :reactions
  ]
end
