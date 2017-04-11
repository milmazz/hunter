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
  defdelegate verify_credentials(conn), to: Hunter.Account

  @doc """
  Retrieve account

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier

  """
  @spec account(Hunter.Client.t, non_neg_integer) :: Hunter.Account.t
  defdelegate account(conn, id), to: Hunter.Account

  @doc """
  Get a list of followers

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier

  """
  @spec followers(Hunter.Client.t, non_neg_integer) :: [Hunter.Account.t]
  defdelegate followers(conn, id), to: Hunter.Account

  @doc """
  Get a list of followed accounts

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier

  """
  @spec following(Hunter.Client.t, non_neg_integer) :: [Hunter.Account.t]
  defdelegate following(conn, id), to: Hunter.Account

  @doc """
  Follow a remote user

  ## Parameters

    * `conn` - connection credentials
    * `uri` - URI of the remote user, in the format of `username@domain`

  """
  @spec follow_by_uri(Hunter.Client.t, URI.t) :: Hunter.Account.t
  defdelegate follow_by_uri(conn, uri), to: Hunter.Account

  @doc """
  Search for accounts

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `q`: what to search for
    * `limit`: maximum number of matching accounts to return, default: 40

  """
  @spec search_account(Hunter.Client.t, Keyword.t) :: [Hunter.Account.t]
  defdelegate search_account(conn, options), to: Hunter.Account

  @doc """
  Retrieve user's blocks

  ## Parameters

    * `conn` - connection credentials

  """
  @spec blocks(Hunter.Client.t) :: [Hunter.Account.t]
  defdelegate blocks(conn), to: Hunter.Account

  @doc """
  Retrieve a list of follow requests

  ## Parameters

    * `conn` - connection credentials

  """
  @spec follow_requests(Hunter.Client.t) :: [Hunter.Account.t]
  defdelegate follow_requests(conn), to: Hunter.Account

  @doc """
  Retrieve user's mutes

  ## Parameters

    * `conn` - connection credentials

  """
  @spec mutes(Hunter.Client.t) :: [Hunter.Account.t]
  defdelegate mutes(conn), to: Hunter.Account

  ## Application

  @doc """
  Register a new OAuth client app on the target instance

  ## Parameters

    * `conn` - connection credentials
    * `name` - name of your application
    * `redirect_uri` - where the user should be redirected after authorization,
      for no redirect, use `urn:ietf:wg:oauth:2.0:oob`
    * `scopes` - scope list, see the scope section for more details
    * `website` - URL to the homepage of your app

  ## Scopes

    * `read` - read data
    * `write` - post statuses and upload media for statuses
    * `follow` - follow, unfollow, block, unblock

  Multiple scopes can be requested during the authorization phase with the `scope` query param

  """
  @spec create_app(String.t, URI.t, String.t, String.t) :: Hunter.Application.t
  defdelegate create_app(name, redirect_uri, scopes, website), to: Hunter.Application

  @doc """
  Initializes a client

  ## Options

    * `base_url` - URL of the instance you want to connect to
    * `bearer_token` - [String] OAuth access token for your authenticated user

  """
  @spec new(Keyword.t) :: Hunter.Client.t
  defdelegate new(options), to: Hunter.Client

  @doc """
  User agent of the client
  """
  @spec user_agent() :: String.t
  defdelegate user_agent, to: Hunter.Client

  @doc """
  Upload a media file

  ## Parameters

    * `conn` - connection credentials
    * `file` - media to be uploaded

  """
  @spec upload_media(Hunter.Client.t, Path.t) :: Hunter.Attachment.t
  defdelegate upload_media(conn, file), to: Hunter.Attachment

  @doc """
  Get the relationships of authenticated user towards given other users

  ## Parameters

    * `conn` - connection credentials
    * `id` - list of relationship IDs

  """
  @spec relationships(Hunter.Client.t, [non_neg_integer]) :: [Hunter.Relationship.t]
  defdelegate relationships(conn, ids), to: Hunter.Relationship

  @doc """
  Follow a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec follow(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  defdelegate follow(conn, id), to: Hunter.Relationship

  @doc """
  Unfollow a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec unfollow(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  defdelegate unfollow(conn, id), to: Hunter.Relationship

  @doc """
  Block a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec block(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  defdelegate block(conn, id), to: Hunter.Relationship

  @doc """
  Unblock a user

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec unblock(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  defdelegate unblock(conn, id), to: Hunter.Relationship

  @doc """
  Mute a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec mute(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  defdelegate mute(conn, id), to: Hunter.Relationship

  @doc """
  Unmute a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec unmute(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  defdelegate unmute(conn, id), to: Hunter.Relationship

  @doc """
  Search for content

  # Parameters

    * `conn` - connection credentials
    * `q` - the search query
    * `options` - option list

  ## Options

    * `resolve` - whether to resolve non-local accounts

  """
  @spec search(String.t, Keyword.t) :: Hunter.Result.t
  defdelegate search(query, options), to: Hunter.Result

  @doc """
  Create new status

  ## Parameters

    * `conn` - connection credentials
    * `text` - [String]
    * `in_reply_to_id` - [Integer]
    * `media_ids` - [Array<Integer>]

  """
  @spec create_status(Hunter.Client.t, String.t, non_neg_integer, [non_neg_integer]) :: Hunter.Status.t
  defdelegate create_status(conn, text, in_reply_to_id, media_ids), to: Hunter.Status

  @doc """
  Retrieve status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec status(Hunter.Client.t, non_neg_integer) :: Hunter.Status.t
  defdelegate status(conn, id), to: Hunter.Status

  @doc """
  Destroy status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec destroy_status(Hunter.Client.t, non_neg_integer) :: boolean
  defdelegate destroy_status(conn, id), to: Hunter.Status

  @doc """
  Reblog a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec reblog(Hunter.Client.t, non_neg_integer) :: Hunter.Status.t
  defdelegate reblog(conn, id), to: Hunter.Status

  @doc """
  Undo a reblog of a status

  ## Parameters

  * `conn` - connection credentials
  * `id` - status identifier

  """
  @spec unreblog(Hunter.Client.t, non_neg_integer) :: Hunter.Status.t
  defdelegate unreblog(conn, id), to: Hunter.Status

  @doc """
  Favorite a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec favourite(Hunter.Client.t, non_neg_integer) :: Hunter.Status.t
  defdelegate favourite(conn, id), to: Hunter.Status

  @doc """
  Undo a favorite of a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec unfavourite(Hunter.Client.t, non_neg_integer) :: Hunter.Status.t
  defdelegate unfavourite(conn, id), to: Hunter.Status

  @doc """
  Fetch a user's favourites

  ## Parameters

    * `conn` - connection credentials

  """
  @spec favourites(Hunter.Client.t) :: [Hunter.Status.t]
  defdelegate favourites(conn), to: Hunter.Status

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
  defdelegate statuses(conn, account_id, options), to: Hunter.Status

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
  defdelegate home_timeline(conn, options), to: Hunter.Status

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
  defdelegate public_timeline(conn, options), to: Hunter.Status

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
  @spec hashtag_timeline(Hunter.Client.t, [String.t], Keyword.t) :: [Hunter.Status.t]
  defdelegate hashtag_timeline(conn, hashtag, options), to: Hunter.Status

  @doc """
  Retrieve instance information

  ## Parameters

    * `conn` - connection credentials

  """
  @spec instance_info(Hunter.Client.t) :: Hunter.Instance.t
  defdelegate instance_info(conn), to: Hunter.Instance

  @doc """
  Retrieve user's notifications

  ## Parameters

    * `conn` - connection credentials

  """
  @spec notifications(Hunter.Client.t) :: [Hunter.Notification.t]
  defdelegate notifications(conn), to: Hunter.Notification

  @doc """
  Retrieve single notification

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification identifier

  """
  @spec notification(Hunter.Client.t, non_neg_integer) :: Hunter.Notification.t
  defdelegate notification(conn, id), to: Hunter.Notification

  @doc """
  Deletes all notifications from the Mastodon server for the authenticated user

  ## Parameters

    * `conn` - connection credentials

  """
  @spec clear_notifications(Hunter.Client.t) :: map
  defdelegate clear_notifications(conn), to: Hunter.Notification

  @doc """
  Retrieve a user's reports

  ## Parameters

    * `conn` - connection credentials

  """
  @spec reports(Hunter.Client.t) :: [Hunter.Report.t]
  defdelegate reports(conn), to: Hunter.Report

  @doc """
  Report a user

  ## Parameters

    * `conn` - connection credentials
    * `account_id` - the ID of the account to report
    * `status_ids` - the IDs of statuses to report
    * `comment` - a comment to associate with the report

  """
  @spec report(Hunter.Client.t, non_neg_integer, [non_neg_integer], String.t) :: Hunter.Report.t
  defdelegate report(conn, account_id, status_ids, comment), to: Hunter.Report

  @doc """
  Retrieve status context

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec status_context(Hunter.Client.t, non_neg_integer) :: Hunter.Context.t
  defdelegate status_context(conn, id), to: Hunter.Context

  @doc """
  Retrieve a card associated with a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status id

  """
  @spec card_by_status(Hunter.Client.t, non_neg_integer) :: Hunter.Card.t
  defdelegate card_by_status(conn, id), to: Hunter.Card

  @doc """
  Returns Hunter version
  """
  @spec version() :: String.t
  def version, do: @hunter_version
end
