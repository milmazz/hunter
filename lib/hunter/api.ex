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

  @doc """
  Search for accounts

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `q`: what to search for
    * `limit`: maximum number of matching accounts to return, default: 40

  """
  @callback search_account(conn :: Hunter.Client.t, options :: Keyword.t) :: [Hunter.Account.t]

  @doc """
  Retrieve user's blocks

  ## Parameters

    * `conn` - connection credentials

  """
  @callback blocks(conn :: Hunter.Client.t) :: [Hunter.Account.t]

  @doc """
  Retrieve a list of follow requests

  ## Parameters

    * `conn` - connection credentials

  """
  @callback follow_requests(conn :: Hunter.Client.t) :: [Hunter.Account.t]

  @doc """
  Retrieve user's mutes

  ## Parameters

    * `conn` - connection credentials

  """
  @callback mutes(conn :: Hunter.Client.t) :: [Hunter.Account.t]

  @doc """
  Accepts or Rejects a follow request

  ## Parameters

    * `conn` - connection credentials
    * `id` - follow request id
    * `action` - action to take

  ## Actions

    * `:authorize` - authorize a follow request
    * `:reject` - reject a follow request

  """
  @callback follow_request_action(conn :: Hunter.Client.t, id :: non_neg_integer, action :: atom) :: boolean

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

    * `conn` - connection credentials
    * `id` - list of relationship IDs

  """
  @callback relationships(conn :: Hunter.Client.t, ids :: [non_neg_integer]) :: [Hunter.Relationship.t]

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
  @callback search(conn :: Hunter.Client.t, query :: String.t, options :: Keyword.t) :: Hunter.Result.t

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
  @callback status(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Status.t

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
  Fetch the list of users who reblogged the status.

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @callback reblogged_by(conn :: Hunter.Client.t, id :: non_neg_integer) :: [Hunter.Account.t]

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
  Fetch the list of users who favourited the status.

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @callback favourited_by(conn :: Hunter.Client.t, id :: non_neg_integer) :: [Hunter.Account.t]

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

  @doc """
  Retrieve instance information

  ## Parameters

    * `conn` - connection credentials

  """
  @callback instance_info(conn :: Hunter.Client.t) :: Hunter.Instance.t

  @doc """
  Retrieve user's notifications

  ## Parameters

    * `conn` - connection credentials

  """
  @callback notifications(conn :: Hunter.Client.t) :: [Hunter.Notification.t]

  @doc """
  Retrieve single notification

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification identifier

  """
  @callback notification(conn :: Hunter.Client.t, non_neg_integer) :: Hunter.Notification.t

  @doc """
  Deletes all notifications from the Mastodon server for the authenticated user

  ## Parameters

    * `conn` - connection credentials

  """
  @callback clear_notifications(conn :: Hunter.Client.t) :: map

  @doc """
  Retrieve a user's reports

  ## Parameters

    * `conn` - connection credentials

  """
  @callback reports(conn :: Hunter.Client.t) :: [Hunter.Report.t]

  @doc """
  Report a user

  ## Parameters

    * `conn` - connection credentials
    * `account_id` - the ID of the account to report
    * `status_ids` - the IDs of statuses to report
    * `comment` - a comment to associate with the report

  """
  @callback report(conn :: Hunter.Client.t, account_id :: non_neg_integer, status_ids :: [non_neg_integer], comment :: String.t) :: Hunter.Report.t

  @doc """
  Retrieve status context

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @callback status_context(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Context.t

  @doc """
  Retrieve a card associated with a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status id

  """
  @callback card_by_status(conn :: Hunter.Client.t, id :: non_neg_integer) :: Hunter.Card.t
end
