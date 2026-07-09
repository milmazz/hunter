defmodule Hunter.Status do
  @moduledoc """
  Status entity

  ## Fields

    * `id` - status id
    * `uri` - a Fediverse-unique resource ID
    * `url` - URL to the status page (can be remote)
    * `account` - the `Hunter.Account` which posted the status
    * `in_reply_to_id` - `nil` or the ID of the status it replies to
    * `in_reply_to_account_id` - `nil` or the ID of the account it replies to
    * `reblog` - `nil` or the reblogged `Hunter.Status`
    * `content` - body of the status; this will contain HTML (remote HTML already sanitized)
    * `created_at` - time the status was created
    * `reblogs_count` - number of reblogs for the status
    * `favourites_count` - number of favourites for the status
    * `reblogged` - whether the authenticated user has reblogged the status
    * `favourited` - whether the authenticated user has favourited the status
    * `muted` - whether the authenticated user has muted the conversation this status from
    * `sensitive` - whether media attachments should be hidden by default
    * `spoiler_text` - if not empty, warning text that should be displayed before the actual content
    * `visibility` - one of: `public`, `unlisted`, `private`, `direct`
    * `media_attachments` - A list of `Hunter.Attachment`
    * `mentions` - list of `Hunter.Mention`
    * `tags` - list of `Hunter.Tag`
    * `application` - `Hunter.Application` from which the status was posted
    * `language` - detected language for the status, default: en
    * `card` - preview card generated for links in the status, if any
    * `emojis` - list of `Hunter.Emoji`, custom emoji used in the status
    * `text` - plain-text source of the status, returned instead of `content`
      when the status is deleted
    * `created_at` - time the status was created
    * `edited_at` - time of the most recent edit, `nil` if never edited
    * `replies_count` - number of replies to the status
    * `bookmarked` - whether the authenticated user has bookmarked the status
    * `pinned` - whether the authenticated user has pinned the status (only
      present on the user's own statuses)
    * `poll` - the `Hunter.Poll` attached to the status, if any
    * `filtered` - list of `Hunter.FilterResult`, filters that matched the
      status for the authenticated user
    * `quote` - the `Hunter.Quote` of another status, if any
    * `quote_approval` - summary of the status' quote approval policy and how
      it applies to the requesting user (`automatic`, `manual` and
      `current_user` keys)

  **NOTE**: When `spoiler_text` is present, `sensitive` is true

  """

  @type t :: %__MODULE__{
          id: String.t(),
          uri: String.t(),
          url: String.t(),
          account: Hunter.Account.t(),
          in_reply_to_id: String.t() | nil,
          in_reply_to_account_id: String.t() | nil,
          reblog: Hunter.Status.t() | nil,
          content: String.t(),
          text: String.t() | nil,
          created_at: String.t(),
          edited_at: String.t() | nil,
          reblogs_count: non_neg_integer,
          favourites_count: non_neg_integer,
          replies_count: non_neg_integer,
          reblogged: boolean,
          favourited: boolean,
          bookmarked: boolean,
          pinned: boolean | nil,
          muted: boolean,
          sensitive: boolean,
          spoiler_text: String.t(),
          visibility: String.t(),
          media_attachments: [Hunter.Attachment.t()],
          mentions: [Hunter.Mention.t()],
          tags: [Hunter.Tag.t()],
          emojis: [Hunter.Emoji.t()],
          application: Hunter.Application.t(),
          language: String.t(),
          card: Hunter.Card.t() | nil,
          poll: Hunter.Poll.t() | nil,
          filtered: [Hunter.FilterResult.t()] | nil,
          quote: Hunter.Quote.t() | nil,
          quote_approval: map | nil
        }

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :uri,
    :url,
    :account,
    :in_reply_to_id,
    :in_reply_to_account_id,
    :reblog,
    :content,
    :text,
    :created_at,
    :edited_at,
    :reblogs_count,
    :favourites_count,
    :replies_count,
    :reblogged,
    :favourited,
    :bookmarked,
    :pinned,
    :muted,
    :sensitive,
    :spoiler_text,
    :visibility,
    :media_attachments,
    :mentions,
    :tags,
    :emojis,
    :application,
    :language,
    :card,
    :poll,
    :filtered,
    :quote,
    :quote_approval
  ]
end
