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
  @callback verify_credentials(conn :: Hunter.Client.t()) :: Hunter.Account.t()

  @doc """
  Make changes to the authenticated user

  ## Parameters

    * `conn` - connection credentials
    * `data` - data payload

  ## Possible keys for payload

    * `display_name` - name to display in the user's profile
    * `note` - new biography for the user
    * `avatar` - base64 encoded image to display as the user's avatar (e.g. `data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAUoAAADrCAYAAAA...`)
    * `header` - base64 encoded image to display as the user's header image (e.g. `data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAUoAAADrCAYAAAA...`)

  """
  @callback update_credentials(Hunter.Client.t(), map) :: Hunter.Account.t()

  @doc """
  Retrieve account

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier

  """
  @callback account(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Account.t()

  @doc """
  Get a list of followers

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier
    * `options` - options list

  ## Options

    * `max_id` - get a list of followings with id less than or equal this value
    * `since_id` - get a list of followings with id greater than this value
    * `limit` - maximum number of followings to get, default: 40, maximum: 80

  """
  @callback followers(conn :: Hunter.Client.t(), id :: non_neg_integer, options :: Keyword.t()) ::
              Hunter.Account.t()

  @doc """
  Get a list of followed accounts

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier
    * `options` - options list

  ## Options

    * `max_id` - get a list of followings with id less than or equal this value
    * `since_id` - get a list of followings with id greater than this value
    * `limit` - maximum number of followings to get, default: 40, maximum: 80

  """
  @callback following(conn :: Hunter.Client.t(), id :: non_neg_integer, options :: Keyword.t()) ::
              Hunter.Account.t()

  @doc """
  Follow a remote user

  ## Parameters

    * `conn` - connection credentials
    * `uri` - URI of the remote user, in the format of `username@domain`

  """
  @callback follow_by_uri(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Account.t()

  @doc """
  Search for accounts

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `q`: what to search for
    * `limit`: maximum number of matching accounts to return, default: 40

  """
  @callback search_account(conn :: Hunter.Client.t(), options :: map) :: [Hunter.Account.t()]

  @doc """
  Retrieve user's blocks

  ## Parameters

    * `conn` - connection credentials

  ## Options

    * `max_id` - get a list of blocks with id less than or equal this value
    * `since_id` - get a list of blocks with id greater than this value
    * `limit` - maximum number of blocks to get, default: 40, max: 80

  """
  @callback blocks(conn :: Hunter.Client.t(), options :: Keyword.t()) :: [Hunter.Account.t()]

  @doc """
  Retrieve a list of follow requests

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of follow requests with id less than or equal this value
    * `since_id` - get a list of follow requests with id greater than this value
    * `limit` - maximum number of requests to get, default: 40, max: 80

  """
  @callback follow_requests(conn :: Hunter.Client.t(), options :: Keyword.t()) :: [
              Hunter.Account.t()
            ]

  @doc """
  Retrieve user's mutes

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of mutes with id less than or equal this value
    * `since_id` - get a list of mutes with id greater than this value
    * `limit` - maximum number of mutes to get, default: 40, max: 80

  """
  @callback mutes(conn :: Hunter.Client.t(), options :: Keyword.t()) :: [Hunter.Account.t()]

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
  @callback follow_request_action(
              conn :: Hunter.Client.t(),
              id :: non_neg_integer,
              action :: atom
            ) :: boolean

  ## Application

  @doc """
  Register a new OAuth client app on the target instance

  ## Parameters

    * `name` - name of your application
    * `redirect_uri` - where the user should be redirected after authorization,
      for no redirect, use `urn:ietf:wg:oauth:2.0:oob`
    * `scopes` - scope list, see the scope section for more details
    * `website` - URL to the homepage of your app
    * `base_url` - base url

  ## Scopes

    * `read` - read data
    * `write` - post statuses and upload media for statuses
    * `follow` - follow, unfollow, block, unblock

  Multiple scopes can be requested during the authorization phase with the `scope` query param

  """
  @callback create_app(
              name :: String.t(),
              redirect_uri :: String.t(),
              scopes :: [String.t()],
              website :: String.t(),
              base_url :: String.t()
            ) :: Hunter.Application.t() | no_return

  @doc """
  Upload a media file

  ## Parameters

    * `conn` - connection credentials
    * `file` - media to be uploaded
    * `options` - option list

  ## Options

    * `description` - plain-text description of the media for accessibility (max 420 chars)
    * `focus` - two floating points, comma-delimited.

  """
  @callback upload_media(conn :: Hunter.Client.t(), file :: Path.t(), options :: Keyword.t()) ::
              Hunter.Attachment.t()

  ## Relationship

  @doc """
  Get the relationships of authenticated user towards given other users

  ## Parameters

    * `conn` - connection credentials
    * `id` - list of relationship IDs

  """
  @callback relationships(conn :: Hunter.Client.t(), ids :: [non_neg_integer]) :: [
              Hunter.Relationship.t()
            ]

  @doc """
  Follow a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user id

  """
  @callback follow(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Relationship.t()

  @doc """
  Unfollow a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @callback unfollow(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Relationship.t()

  @doc """
  Block a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @callback block(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Relationship.t()

  @doc """
  Unblock a user

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @callback unblock(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Relationship.t()

  @doc """
  Mute a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @callback mute(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Relationship.t()

  @doc """
  Unmute a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @callback unmute(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Relationship.t()

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
  @callback search(conn :: Hunter.Client.t(), query :: String.t(), options :: Keyword.t()) ::
              Hunter.Result.t()

  ## Status

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
  @callback create_status(conn :: Hunter.Client.t(), status :: String.t(), options :: Keyword.t()) ::
              Hunter.Status.t() | no_return

  @doc """
  Retrieve status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @callback status(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Status.t()

  @doc """
  Destroy status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @callback destroy_status(conn :: Hunter.Client.t(), id :: non_neg_integer) :: boolean

  @doc """
  Reblog a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @callback reblog(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Status.t()

  @doc """
  Undo a reblog of a status

  ## Parameters

  * `conn` - connection credentials
  * `id` - status identifier

  """
  @callback unreblog(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Status.t()

  @doc """
  Fetch the list of users who reblogged the status.

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier
    * `options` - option list

  ## Options

    * `max_id` - get a list of *reblogged by* ids less than or equal this value
    * `since_id` - get a list of *reblogged by* ids greater than this value
    * `limit` - maximum number of *reblogged by* to get, default: 40, max: 80

  """
  @callback reblogged_by(conn :: Hunter.Client.t(), id :: non_neg_integer, options :: Keyword.t()) ::
              [Hunter.Account.t()]

  @doc """
  Favorite a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @callback favourite(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Status.t()

  @doc """
  Undo a favorite of a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @callback unfavourite(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Status.t()

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
  @callback favourites(conn :: Hunter.Client.t(), options :: Keyword.t()) :: [Hunter.Status.t()]

  @doc """
  Fetch the list of users who favourited the status.

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier
    * `options` - option list

  ## Options

    * `max_id` - get a list of *favourited by* ids less than or equal this value
    * `since_id` - get a list of *favourited by* ids greater than this value
    * `limit` - maximum number of *favourited by* to get, default: 40, max: 80

  """
  @callback favourited_by(
              conn :: Hunter.Client.t(),
              id :: non_neg_integer,
              options :: Keyword.t()
            ) :: [Hunter.Account.t()]

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
  @callback statuses(conn :: Hunter.Client.t(), account_id :: non_neg_integer, options :: map) ::
              [Hunter.Status.t()]

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
  @callback home_timeline(conn :: Hunter.Client.t(), options :: map) :: [Hunter.Status.t()]

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
  @callback public_timeline(conn :: Hunter.Client.t(), options :: map) :: [Hunter.Status.t()]

  @doc """
  Retrieve statuses from a hashtag

  ## Parameters

    * `conn` - connection credentials
    * `hashtag` - list of strings
    * `options` - option list

  ## Options

    * `local` - only return statuses originating from this instance
    * `max_id` - get a list of timelines with id less than or equal this value
    * `since_id` - get a list of timelines with id greater than this value
    * `limit` - maximum number of statuses on the requested timeline to get, default: 20, max: 40

  """
  @callback hashtag_timeline(conn :: Hunter.Client.t(), hashtag :: [String.t()], options :: map) ::
              [Hunter.Status]

  @doc """
  Retrieve instance information

  ## Parameters

    * `conn` - connection credentials

  """
  @callback instance_info(conn :: Hunter.Client.t()) :: Hunter.Instance.t()

  @doc """
  Retrieve user's notifications

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of notifications with id less than or equal this value
    * `since_id` - get a list of notifications with id greater than this value
    * `limit` - maximum number of notifications to get, default: 15, max: 30

  """
  @callback notifications(conn :: Hunter.Client.t(), options :: Keyword.t()) :: [
              Hunter.Notification.t()
            ]

  @doc """
  Retrieve single notification

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification identifier

  """
  @callback notification(conn :: Hunter.Client.t(), non_neg_integer) :: Hunter.Notification.t()

  @doc """
  Deletes all notifications from the Mastodon server for the authenticated user

  ## Parameters

    * `conn` - connection credentials

  """
  @callback clear_notifications(conn :: Hunter.Client.t()) :: boolean

  @doc """
  Dismiss a single notification

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification id

  """
  @callback clear_notification(conn :: Hunter.Client.t(), id :: non_neg_integer) :: boolean

  @doc """
  Retrieve a user's reports

  ## Parameters

    * `conn` - connection credentials

  """
  @callback reports(conn :: Hunter.Client.t()) :: [Hunter.Report.t()]

  @doc """
  Report a user

  ## Parameters

    * `conn` - connection credentials
    * `account_id` - the ID of the account to report
    * `status_ids` - the IDs of statuses to report
    * `comment` - a comment to associate with the report

  """
  @callback report(
              conn :: Hunter.Client.t(),
              account_id :: non_neg_integer,
              status_ids :: [non_neg_integer],
              comment :: String.t()
            ) :: Hunter.Report.t()

  @doc """
  Retrieve status context

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @callback status_context(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Context.t()

  @doc """
  Retrieve a card associated with a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status id

  """
  @callback card_by_status(conn :: Hunter.Client.t(), id :: non_neg_integer) :: Hunter.Card.t()

  @doc """
  Retrieve access token

  ## Parameters

    * `app` - application details, see: `Hunter.Application.create_app/5` for more details.
    * `username` - your account's email
    * `password` - your password
    * `base_url` - API base url, default: `https://mastodon.social`

  """
  @callback log_in(
              app :: Hunter.Application.t(),
              username :: String.t(),
              password :: String.t(),
              base_url :: String.t()
            ) :: Hunter.Client.t()

  @doc """
  Fetch user's blocked domains

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of blocks with id less than or equal this value
    * `since_id` - get a list of blocks with id greater than this value
    * `limit` - maximum number of blocks to get, default: 40, max: 80

  """
  @callback blocked_domains(conn :: Hunter.Client.t(), options :: Keyword.t()) :: list

  @doc """
  Block a domain

  ## Parameters

    * `conn` - connection credentials
    * `domain` - domain to block

  """
  @callback block_domain(conn :: Hunter.Client.t(), domain :: String.t()) :: boolean

  @doc """
  Unblock a domain

  ## Parameters

    * `conn` - connection credentials
    * `domain` - domain to unblock

  """
  @callback unblock_domain(conn :: Hunter.Client.t(), domain :: String.t()) :: boolean
end
