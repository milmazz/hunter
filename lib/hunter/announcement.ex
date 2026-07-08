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

  defmodule Reaction do
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
end
