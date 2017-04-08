defmodule Hunter do
  @moduledoc """
  A Elixir client for Mastodon, a GNU Social compatible micro-blogging service

  """

  @hunter_version Mix.Project.config[:version]

  @doc """
  Retrieve account of authenticated user

  ## Parameters

    * `conn` - connection credentials

  """
  @spec verify_credentials(Hunter.Client.t) :: Hunter.Account.t
  def verify_credentials(conn), do: Hunter.Account.verify_credentials(conn)

  @doc """
  Retrieve account

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier

  """
  @spec account(Hunter.Client.t, non_neg_integer) :: Hunter.Account.t
  def account(conn, id), do: Hunter.Account.account(conn, id)

  @doc """
  Get a list of followers

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier

  """
  @spec followers(Hunter.Client.t, non_neg_integer) :: [Hunter.Account.t]
  def followers(conn, id), do: Hunter.Account.followers(conn, id)

  @doc """
  Get a list of followed accounts

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier

  """
  @spec following(Hunter.Client.t, non_neg_integer) :: [Hunter.Account.t]
  def following(conn, id), do: Hunter.Account.following(conn, id)

  @doc """
  Follow a remote user

  ## Parameters

    * `conn` - connection credentials
    * `uri` - URI of the remote user, in the format of `username@domain`

  """
  @spec follow_by_uri(Hunter.Client.t, URI.t) :: Hunter.Account.t
  def follow_by_uri(conn, uri), do: Hunter.Account.follow_by_uri(conn, uri)

  @doc """
  Register a new OAuth client app on the target instance

  ## Parameters

    * `name`
    * `redirect_uri`
    * `scopes`
    * `website`

  """
  @spec create_app(String.t, URI.t, String.t, String.t) :: Hunter.Application.t
  def create_app(name, redirect_uri, scopes \\ "read", website \\ nil) do
    Hunter.Application.create_app(name, redirect_uri, scopes, website)
  end

  @doc """
  Initializes a client

  ## Options

    * `base_url` - URL of the instance you want to connect to
    * `bearer_token` - [String] OAuth access token for your authenticated user

  """
  @spec new(Keyword.t) :: Hunter.Client.t
  def new(options \\ []), do: Hunter.Client.new(options)

  @doc """
  User agent of the client
  """
  @spec user_agent() :: String.t
  def user_agent, do: Hunter.Client.user_agent()

  @doc """
  Upload a media file

  ## Parameters

    * `conn` - connection credentials
    * `file` - media to be uploaded

  """
  @spec upload_media(Hunter.Client.t, Path.t) :: Hunter.Attachment.t
  def upload_media(conn, file), do: Hunter.Attachment.upload_media(conn, file)

  @doc """
  Get the relationships of authenticated user towards given other users

  ## Parameters

    * `id` - list of relationship IDs

  """
  @spec relationships([non_neg_integer]) :: [Hunter.Relationship.t]
  def relationships(ids), do: Hunter.Relationship.relationships(ids)

  @doc """
  Follow a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec follow(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  def follow(conn, id), do: Hunter.Relationship.follow(conn, id)

  @doc """
  Unfollow a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec unfollow(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  def unfollow(conn, id), do: Hunter.Relationship.unfollow(conn, id)

  @doc """
  Block a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec block(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  def block(conn, id), do: Hunter.Relationship.block(conn, id)

  @doc """
  Unblock a user

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec unblock(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  def unblock(conn, id), do: Hunter.Relationship.unblock(conn, id)

  @doc """
  Mute a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec mute(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  def mute(conn, id), do: Hunter.Relationship.mute(conn, id)

  @doc """
  Unmute a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec unmute(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  def unmute(conn, id), do: Hunter.Relationship.unmute(conn, id)

  @doc """
  Search for content

  # Parameters

    * `q` - search query

  ## Options

    * `resolve` - whether to resolve non-local accounts

  """
  @spec search(String.t, Keyword.t) :: Hunter.Result.t
  def search(query, options \\ []), do: Hunter.Result.search(query, options)

  @doc """
  Create new status

  ## Parameters

    * `conn` - connection credentials
    * `text` - [String]
    * `in_reply_to_id` - [Integer]
    * `media_ids` - [Array<Integer>]

  """
  @spec create_status(Hunter.Client.t, String.t, non_neg_integer, [non_neg_integer]) :: Hunter.Status.t
  def create_status(conn, text, in_reply_to_id \\ nil, media_ids \\ []) do
    Hunter.Status.create_status(conn, text, in_reply_to_id, media_ids)
  end

  @doc """
  Retrieve status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec status(Hunter.Client.t, non_neg_integer) :: Hunter.Status.t
  def status(conn, id), do: Hunter.Status.status(conn, id)

  @doc """
  Destroy status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec destroy_status(Hunter.Client.t, non_neg_integer) :: boolean
  def destroy_status(conn, id), do: Hunter.Status.destroy_status(conn, id)

  @doc """
  Reblog a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec reblog(Hunter.Client.t, non_neg_integer) :: Hunter.Status.t
  def reblog(conn, id), do: Hunter.Status.reblog(conn, id)

  @doc """
  Undo a reblog of a status

  ## Parameters

  * `conn` - connection credentials
  * `id` - status identifier

  """
  @spec unreblog(Hunter.Client.t, non_neg_integer) :: Hunter.Status.t
  def unreblog(conn, id), do: Hunter.Status.unreblog(conn, id)

  @doc """
  Favorite a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec favourite(Hunter.Client.t, non_neg_integer) :: Hunter.Status.t
  def favourite(conn, id), do: Hunter.Status.favourite(conn, id)

  @doc """
  Undo a favorite of a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec unfavourite(Hunter.Client.t, non_neg_integer) :: Hunter.Status.t
  def unfavourite(conn, id), do: Hunter.Status.unfavourite(conn, id)

  @doc """
  Get a list of statuses by a user

  ## Parameters

    * `conn` - connection credentials -
    * `account_id` - account identifier
    * `options` - option list

  ## Options

    * `max_id` - [Integer]
    * `since_id` - [Integer]
    * `limit` - [Integer]

  """
  @spec statuses(Hunter.Client.t, non_neg_integer, Keyword.t) :: [Hunter.Status.t]
  def statuses(conn, account_id, options \\ []) do
    Hunter.Status.statuses(conn, account_id, options)
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
    Hunter.Status.home_timeline(conn, options)
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
    Hunter.Status.public_timeline(conn, options)
  end

  @doc """
  Retrieve statuses from a hashtag

  ## Parameters

    * `conn` - connection credentials
    * `hashtag` - string list

  ## Options

  * `max_id` - [Integer]
  * `since_id` - [Integer]
  * `limit` - [Integer]

  """
  @spec hashtag_timeline(Hunter.Client.t, Keyword.t) :: [Hunter.Status.t]
  def hashtag_timeline(conn, hashtag, options \\ []) do
    Hunter.Status.hashtag_timeline(conn, hashtag, options)
  end

  @doc """
  Returns Hunter version
  """
  @spec version() :: String.t
  def version, do: @hunter_version
end
