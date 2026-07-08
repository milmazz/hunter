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
  alias Hunter.Config

  @type t :: %__MODULE__{
          id: non_neg_integer,
          uri: String.t(),
          url: String.t(),
          account: Hunter.Account.t(),
          in_reply_to_id: non_neg_integer,
          in_reply_to_account_id: non_neg_integer,
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

  @type status_id :: non_neg_integer

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

  @doc """
  Create new status

  ## Parameters

    * `conn` - connection credentials
    * `status` - text of the status
    * `options` - option list

  ## Options

    * `in_reply_to_id` - local ID of the status you want to reply to
    * `media_ids` - list of media IDs to attach to the status (maximum: 4)
    * `sensitive` - whether the media of the status is NSFW
    * `spoiler_text` - text to be shown as a warning before the actual content
    * `visibility` - either `direct`, `private`, `unlisted` or `public`

  """
  @spec create_status(Hunter.Client.t(), String.t(), Keyword.t()) :: Hunter.Status.t() | no_return
  def create_status(conn, status, options \\ []) do
    Config.hunter_api().create_status(conn, status, options)
  end

  @doc """
  Retrieve status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec status(Hunter.Client.t(), status_id) :: Hunter.Status.t()
  def status(conn, id) do
    Config.hunter_api().status(conn, id)
  end

  @doc """
  Destroy status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec destroy_status(Hunter.Client.t(), status_id) :: boolean
  def destroy_status(conn, id) do
    Config.hunter_api().destroy_status(conn, id)
  end

  @doc """
  Reblog a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec reblog(Hunter.Client.t(), status_id) :: Hunter.Status.t()
  def reblog(conn, id) do
    Config.hunter_api().reblog(conn, id)
  end

  @doc """
  Undo a reblog of a status

  ## Parameters

  * `conn` - connection credentials
  * `id` - status identifier

  """
  @spec unreblog(Hunter.Client.t(), status_id) :: Hunter.Status.t()
  def unreblog(conn, id) do
    Config.hunter_api().unreblog(conn, id)
  end

  @doc """
  Favorite a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec favourite(Hunter.Client.t(), status_id) :: Hunter.Status.t()
  def favourite(conn, id) do
    Config.hunter_api().favourite(conn, id)
  end

  @doc """
  Undo a favorite of a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec unfavourite(Hunter.Client.t(), status_id) :: Hunter.Status.t()
  def unfavourite(conn, id) do
    Config.hunter_api().unfavourite(conn, id)
  end

  @doc """
  Fetch a user's favourites

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of favourites with id less than or equal this value
    * `since_id` - get a list of favourites with id greater than this value
    * `limit` - maximum of favourites to get, default: 20, max: 40

  """
  @spec favourites(Hunter.Client.t(), Keyword.t()) :: [Hunter.Status.t()]
  def favourites(conn, options \\ []) do
    Config.hunter_api().favourites(conn, options)
  end

  @doc """
  Get a list of statuses by a user

  ## Parameters

    * `conn` - connection credentials
    * `account_id` - account identifier
    * `options` - option list

  ## Options

    * `only_media` - only return `Hunter.Status.t` that have media attachments
    * `exclude_replies` - skip statuses that reply to other statuses
    * `max_id` - get a list of statuses with id less than or equal this value
    * `since_id` - get a list of statuses with id greater than this value
    * `limit` - maximum number of statuses to get, default: 20, max: 40

  """
  @spec statuses(Hunter.Client.t(), status_id, Keyword.t()) :: [Hunter.Status.t()]
  def statuses(conn, account_id, options \\ []) do
    Config.hunter_api().statuses(conn, account_id, Map.new(options))
  end

  @doc """
  Retrieve statuses from the home timeline

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of timelines with id less than or equal this value
    * `since_id` - get a list of timelines with id greater than this value
    * `limit` - maximum number of statuses on the requested timeline to get, default: 20, max: 40

  """
  @spec home_timeline(Hunter.Client.t(), Keyword.t()) :: [Hunter.Status.t()]
  def home_timeline(conn, options \\ []) do
    Config.hunter_api().home_timeline(conn, Map.new(options))
  end

  @doc """
  Retrieve statuses from the public timeline

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `local` - only return statuses originating from this instance
    * `max_id` - get a list of timelines with id less than or equal this value
    * `since_id` - get a list of timelines with id greater than this value
    * `limit` - maximum number of statuses on the requested timeline to get, default: 20, max: 40

  """
  @spec public_timeline(Hunter.Client.t(), Keyword.t()) :: [Hunter.Status.t()]
  def public_timeline(conn, options \\ []) do
    Config.hunter_api().public_timeline(conn, Map.new(options))
  end

  @doc """
  Retrieve statuses from a hashtag

  ## Parameters

    * `conn` - connection credentials
    * `hashtag` - string list
    * `options` - option list

  ## Options

    * `local` - only return statuses originating from this instance
    * `max_id` - get a list of timelines with id less than or equal this value
    * `since_id` - get a list of timelines with id greater than this value
    * `limit` - maximum number of statuses on the requested timeline to get, default: 20, max: 40

  """
  @spec hashtag_timeline(Hunter.Client.t(), [String.t()], Keyword.t()) :: [Hunter.Status.t()]
  def hashtag_timeline(conn, hashtag, options \\ []) do
    Config.hunter_api().hashtag_timeline(conn, hashtag, Map.new(options))
  end
end
