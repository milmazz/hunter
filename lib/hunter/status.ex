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
    * `sensitive` - whether media attachments should be hidden by default
    * `spoiler_text` - if not empty, warning text that should be displayed before the actual content
    * `visibility` - one of: `public`, `unlisted`, `private`, `direct`
    * `media_attachments` - A list of `Hunter.Attachment`
    * `mentions` - list of `Hunter.Mention`
    * `tags` - list of `Hunter.Tag`
    * `application` - `Hunter.Application` from which the status was posted

  """
  @hunter_api Application.get_env(:hunter, :hunter_api)

  @type t :: %__MODULE__{
    id: non_neg_integer,
    uri: URI.t,
    url: URI.t,
    account: Hunter.Account.t,
    in_reply_to_id: non_neg_integer,
    reblog: Hunter.Status.t | nil,
    content: String.t,
    created_at: String.t,
    reblogs_count: non_neg_integer,
    favourites_count: non_neg_integer,
    reblogged: boolean,
    favourited: boolean,
    sensitive: boolean,
    spoiler_text: String.t,
    media_attachments: [Hunter.Attachment.t],
    mentions: [Hunter.Mention.t],
    tags: [Hunter.Tag.t],
    application: Hunter.Application.t
  }

  @type status_id :: non_neg_integer

  @derive [Poison.Encoder]
  defstruct [:id,
             :uri,
             :url,
             :account,
             :in_reply_to_id,
             :in_reply_to_account_id,
             :reblog,
             :content,
             :created_at,
             :reblogs_count,
             :favourites_count,
             :reblogged,
             :favourited,
             :sensitive,
             :spoiler_text,
             :visibility,
             :media_attachments,
             :mentions,
             :tags,
             :application]

  @doc """
  Create new status

  ## Parameters

    * `conn` - connection credentials
    * `text` - [String]
    * `in_reply_to_id` - status identifier
    * `media_ids` - [Array<Integer>]

  """
  @spec create_status(Hunter.Client.t, String.t, status_id, [status_id]) :: Hunter.Status.t
  def create_status(conn, text, in_reply_to_id \\ nil, media_ids \\ []) do
    @hunter_api.create_status(conn, text, in_reply_to_id, media_ids)
  end

  @doc """
  Retrieve status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec status(Hunter.Client.t, status_id) :: Hunter.Status.t
  def status(conn, id) do
    @hunter_api.status(conn, id)
  end

  @doc """
  Destroy status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec destroy_status(Hunter.Client.t, status_id) :: boolean
  def destroy_status(conn, id) do
    @hunter_api.destroy_status(conn, id)
  end

  @doc """
  Reblog a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec reblog(Hunter.Client.t, status_id) :: Hunter.Status.t
  def reblog(conn, id) do
    @hunter_api.reblog(conn, id)
  end

  @doc """
  Undo a reblog of a status

  ## Parameters

  * `conn` - connection credentials
  * `id` - status identifier

  """
  @spec unreblog(Hunter.Client.t, status_id) :: Hunter.Status.t
  def unreblog(conn, id) do
    @hunter_api.unreblog(conn, id)
  end

  @doc """
  Fetch the list of users who reblogged the status.

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier
  """
  @spec reblogged_by(Hunter.Client.t, non_neg_integer) :: Hunter.Status.t
  def reblogged_by(conn, id) do
    @hunter_api.reblogged_by(conn, id)
  end

  @doc """
  Favorite a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec favourite(Hunter.Client.t, status_id) :: Hunter.Status.t
  def favourite(conn, id) do
    @hunter_api.favourite(conn, id)
  end

  @doc """
  Undo a favorite of a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec unfavourite(Hunter.Client.t, status_id) :: Hunter.Status.t
  def unfavourite(conn, id) do
    @hunter_api.unfavourite(conn, id)
  end

  @doc """
  Fetch a user's favourites

  ## Parameters

    * `conn` - connection credentials

  """
  @spec favourites(Hunter.Client.t) :: [Hunter.Status.t]
  def favourites(conn) do
    @hunter_api.favourites(conn)
  end

  @doc """
  Fetch the list of users who favourited the status
  
  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """

  @spec favourited_by(Hunter.Client.t, status_id) :: [Hunter.Status.t]
  def favourited_by(conn, id) do
    @hunter_api.favourited_by(conn, id)
  end

  @doc """
  Get a list of statuses by a user

  ## Parameters

    * `conn` - connection credentials
    * `account_id` - account identifier
    * `options` - option list

  ## Options

    * `max_id` - [Integer]
    * `since_id` - [Integer]
    * `limit` - [Integer]

  """
  @spec statuses(Hunter.Client.t, status_id, Keyword.t) :: [Hunter.Status.t]
  def statuses(conn, account_id, options \\ []) do
    @hunter_api.statuses(conn, account_id, options)
  end

  @doc """
  Retrieve statuses from the home timeline

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - [Integer]
    * `since_id` - [Integer]
    * `limit` - [Integer]

  """
  @spec home_timeline(Hunter.Client.t, Keyword.t) :: [Hunter.Status.t]
  def home_timeline(conn, options \\ []) do
    @hunter_api.home_timeline(conn, options)
  end

  @doc """
  Retrieve statuses from the public timeline

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

  * `max_id` - [Integer]
  * `since_id` - [Integer]
  * `limit` - [Integer]

  """
  @spec public_timeline(Hunter.Client.t, Keyword.t) :: [Hunter.Status.t]
  def public_timeline(conn, options \\ []) do
    @hunter_api.public_timeline(conn, options)
  end

  @doc """
  Retrieve statuses from a hashtag

  ## Parameters

    * `conn` - connection credentials
    * `hashtag` - string list
    * `options` - option list

  ## Options

  * `max_id` - [Integer]
  * `since_id` - [Integer]
  * `limit` - [Integer]

  """
  @spec hashtag_timeline(Hunter.Client.t, [String.t], Keyword.t) :: [Hunter.Status.t]
  def hashtag_timeline(conn, hashtag, options \\ []) do
    @hunter_api.hashtag_timeline(conn, hashtag, options)
  end
end
