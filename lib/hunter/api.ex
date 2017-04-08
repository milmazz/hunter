defmodule Hunter.Api do
  @moduledoc """
  Hunter API contract
  """

  ## Account

  @doc """
  Retrieve account of authenticated user

  ## Parameters

    * `conn` - connection credentials

  """
  @callback verify_credentials(conn :: Hunter.Client.t) :: Hunter.Account.t

  @doc """
  Retrieve account

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier

  """
  @callback account(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Account.t

  @doc """
  Get a list of followers

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier

  """
  @callback followers(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Account.t

  @doc """
  Get a list of followed accounts

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier

  """
  @callback following(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Account.t

  @doc """
  Follow a remote user

  ## Parameters

    * `conn` - connection credentials
    * `uri` - URI of the remote user, in the format of `username@domain`

  """
  @callback follow_by_uri(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Account.t

  ## Application

  @doc """
  Register a new OAuth client app on the target instance

  ## Parameters

    * `conn` - connection credentials
    * `name`
    * `redirect_uri`
    * `scopes`
    * `website`

  """
  @callback create_app(conn :: Hunter.Client.t, name :: String.t, redirect_uri :: URI.t, scopes :: String.t, website :: String.t) :: Hunter.Application.t

  @doc """
  Upload a media file

  ## Parameters

    * `conn` - connection credentials
    * `file` - media to be uploaded

  """
  @callback upload_media(conn :: Hunter.Client.t, file :: Path.t) :: Hunter.Attachment.t

  ## Relationship

  @doc """
  Get the relationships of authenticated user towards given other users

  ## Parameters

    * `id` - list of relationship IDs

  """
  @callback relationships(ids :: [non_neg_integer]) :: [Hunter.Relationship.t]

  @doc """
  Follow a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user id

  """
  @callback follow(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Relationship.t

  @doc """
  Unfollow a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @callback unfollow(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Relationship.t

  @doc """
  Block a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @callback block(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Relationship.t

  @doc """
  Unblock a user

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @callback unblock(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Relationship.t

  @doc """
  Mute a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @callback mute(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Relationship.t

  @doc """
  Unmute a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @callback unmute(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Relationship.t

  ## Result

  @doc """
  Search for content

  ## Parameters

    * `conn` - connection credentials
    * `q` - the search query
    * `options` - option list

  ## Options

    * `resolve` - whether to resolve non-local accounts

  """
  @callback search(Hunter.Client.t, query :: String.t, options :: Keyword.t) :: Hunter.Result.t

  ## Status

  @doc """
  Create new status

  ## Parameters

    * `conn` - connection credentials
    * `text` - [String]
    * `in_reply_to_id` - [Integer]
    * `media_ids` - [Array<Integer>]

  """
  @callback create_status(conn :: Hunter.Client.t, text :: String.t, in_reply_to_id :: non_neg_integer, media_ids :: [non_neg_integer]) :: Hunter.Status.t

  @doc """
  Retrieve status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @callback status(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Status

  @doc """
  Destroy status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @callback destroy_status(conn :: Hunter.Client.t, id :: non_neg_integer) :: boolean

  @doc """
  Reblog a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @callback reblog(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Status.t

  @doc """
  Undo a reblog of a status

  ## Parameters

  * `conn` - connection credentials
  * `id` - status identifier

  """
  @callback unreblog(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Status.t

  @doc """
  Favorite a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @callback favourite(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Status.t

  @doc """
  Undo a favorite of a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @callback unfavourite(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Status.t

  @doc """
  Fetch a user's favourites

  ## Parameters

    * `conn` - connection credentials

  """
  @callback favourites(conn :: Hunter.Client.t) :: [Hunter.Status.t]

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
  @callback statuses(conn :: Hunter.Client.t, account_id :: non_neg_integer, options :: Keyword.t) :: [Hunter.Status.t]

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
  @callback home_timeline(conn :: Hunter.Client.t, options :: Keyword.t) :: [Hunter.Status.t]

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
  @callback public_timeline(conn :: Hunter.Client.t, options :: Keyword.t) :: [Hunter.Status.t]

  @doc """
  Retrieve statuses from a hashtag

  ## Parameters

    * `conn` - connection credentials
    * `hashtag` - list of strings

  ## Options

  * `max_id` - [Integer]
  * `since_id` - [Integer]
  * `limit` - [Integer]

  """
  @callback hashtag_timeline(conn :: Hunter.Client.t, hashtag :: [String.t], options :: Keyword.t) :: [Hunter.Status]
end
