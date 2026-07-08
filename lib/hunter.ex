defmodule Hunter do
  @moduledoc """
  An Elixir client for the Mastodon API
  """

  @hunter_version Mix.Project.config()[:version]

  @doc """
  Retrieve account of authenticated user

  ## Parameters

    * `conn` - connection credentials

  """
  @spec verify_credentials(Hunter.Client.t()) :: Hunter.Account.t()
  defdelegate verify_credentials(conn), to: Hunter.Account

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
  @spec update_credentials(Hunter.Client.t(), map) :: Hunter.Account.t()
  defdelegate update_credentials(conn, data), to: Hunter.Account

  @doc """
  Retrieve account

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier

  """
  @spec account(Hunter.Client.t(), non_neg_integer) :: Hunter.Account.t()
  defdelegate account(conn, id), to: Hunter.Account

  @doc """
  Get a list of followers

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier
    * `options` - options list

  ## Options

    * `max_id` - get a list of followers with id less than or equal this value
    * `since_id` - get a list of followers with id greater than this value
    * `limit` - maximum number of followers to get, default: 40, maximum: 80

  """
  @spec followers(Hunter.Client.t(), non_neg_integer, Keyword.t()) :: [Hunter.Account.t()]
  defdelegate followers(conn, id, options \\ []), to: Hunter.Account

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
  @spec following(Hunter.Client.t(), non_neg_integer, Keyword.t()) :: [Hunter.Account.t()]
  defdelegate following(conn, id, options \\ []), to: Hunter.Account

  @doc """
  Search for accounts

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `q`: what to search for
    * `limit`: maximum number of matching accounts to return, default: 40

  """
  @spec search_account(Hunter.Client.t(), Keyword.t()) :: [Hunter.Account.t()]
  defdelegate search_account(conn, options), to: Hunter.Account

  @doc """
  Retrieve user's blocks

  ## Parameters

    * `conn` - connection credentials

  ## Options

    * `max_id` - get a list of blocks with id less than or equal this value
    * `since_id` - get a list of blocks with id greater than this value
    * `limit` - maximum number of blocks to get, default: 40, max: 80

  """
  @spec blocks(Hunter.Client.t(), Keyword.t()) :: [Hunter.Account.t()]
  defdelegate blocks(conn, options \\ []), to: Hunter.Account

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
  @spec follow_requests(Hunter.Client.t(), Keyword.t()) :: [Hunter.Account.t()]
  defdelegate follow_requests(conn, options \\ []), to: Hunter.Account

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
  @spec mutes(Hunter.Client.t(), Keyword.t()) :: [Hunter.Account.t()]
  defdelegate mutes(conn, options \\ []), to: Hunter.Account

  @doc """
  Accepts a follow request

  ## Parameters

    * `conn` - connection credentials
    * `id` - follow request id

  """
  @spec accept_follow_request(Hunter.Client.t(), non_neg_integer) :: Hunter.Relationship.t()
  defdelegate accept_follow_request(conn, id), to: Hunter.Account

  @doc """
  Rejects a follow request

  ## Parameters

    * `conn` - connection credentials
    * `id` - follow request id

  """
  @spec reject_follow_request(Hunter.Client.t(), non_neg_integer) :: Hunter.Relationship.t()
  defdelegate reject_follow_request(conn, id), to: Hunter.Account

  ## Application

  @doc """
  Register a new OAuth client app on the target instance

  ## Parameters

    * `name` - name of your application
    * `redirect_uri` - where the user should be redirected after authorization,
      default: `urn:ietf:wg:oauth:2.0:oob` (no redirect)
    * `scopes` - scope list, see the scope section for more details, default: `read`
    * `website` - URL to the homepage of your app, default: `nil`
    * `options` - option list

  ## Scopes

    * `read` - read data
    * `write` - post statuses and upload media for statuses
    * `follow` - follow, unfollow, block, unblock

  Multiple scopes can be requested during the authorization phase with the `scope` query param

  ## Options

    * `save?` - persists your application information to a file, so, you can use
      them later. default: `false`
    * `api_base_url` - specifies if you want to register an application on a
      different instance. default: `https://mastodon.social`

  """
  @spec create_app(String.t(), String.t(), [String.t()], nil | String.t(), Keyword.t()) ::
          Hunter.Application.t() | no_return
  defdelegate create_app(
                name,
                redirect_uri \\ "urn:ietf:wg:oauth:2.0:oob",
                scopes \\ ["read"],
                website \\ nil,
                options \\ []
              ),
              to: Hunter.Application

  @doc """
  Load persisted application's credentials

  ## Parameters

    * `name` - application's name

  """
  @spec load_credentials(String.t()) :: Hunter.Application.t()
  defdelegate load_credentials(name), to: Hunter.Application

  @doc """
  Initializes a client

  ## Options

    * `base_url` - URL of the instance you want to connect to
    * `access_token` - [String] OAuth access token for your authenticated user

  """
  @spec new(Keyword.t()) :: Hunter.Client.t()
  defdelegate new(options \\ []), to: Hunter.Client

  @doc """
  User agent of the client
  """
  @spec user_agent() :: String.t()
  defdelegate user_agent, to: Hunter.Client

  @doc """
  Upload a media file

  ## Parameters

    * `conn` - connection credentials
    * `file` - media to be uploaded
    * `options` - option list

  ## Options

    * `description` - plain-text description of the media for accessibility (max 420 chars)
    * `focus` - two floating points, comma-delimited

  **Note:** the v2 media endpoint processes large files asynchronously: the
  returned attachment's `url` may be `nil` until the server finishes
  processing (HTTP 202). The `id` can be attached to a status with
  `create_status` as soon as processing completes.

  """
  @spec upload_media(Hunter.Client.t(), Path.t(), Keyword.t()) :: Hunter.Attachment.t()
  defdelegate upload_media(conn, file, options \\ []), to: Hunter.Attachment

  @doc """
  Retrieve a media attachment, to check the processing status of an
  asynchronous upload

  ## Parameters

    * `conn` - connection credentials
    * `id` - attachment identifier

  """
  @spec media_attachment(Hunter.Client.t(), non_neg_integer) :: Hunter.Attachment.t()
  defdelegate media_attachment(conn, id), to: Hunter.Attachment

  @doc """
  Update a media attachment, before it is attached to a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - attachment identifier
    * `options` - option list

  ## Options

    * `description` - plain-text description of the media for accessibility
    * `focus` - two floating points between -1.0 and 1.0, comma-delimited
    * `thumbnail` - path of a custom thumbnail image

  """
  @spec update_media(Hunter.Client.t(), non_neg_integer, Keyword.t()) :: Hunter.Attachment.t()
  defdelegate update_media(conn, id, options \\ []), to: Hunter.Attachment

  @doc """
  Delete a media attachment that is not currently attached to a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - attachment identifier

  """
  @spec delete_media(Hunter.Client.t(), non_neg_integer) :: boolean
  defdelegate delete_media(conn, id), to: Hunter.Attachment

  @doc """
  Get the relationships of authenticated user towards given other users

  ## Parameters

    * `conn` - connection credentials
    * `id` - list of relationship IDs

  """
  @spec relationships(Hunter.Client.t(), [non_neg_integer]) :: [Hunter.Relationship.t()]
  defdelegate relationships(conn, ids), to: Hunter.Relationship

  @doc """
  Follow a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec follow(Hunter.Client.t(), non_neg_integer) :: Hunter.Relationship.t()
  defdelegate follow(conn, id), to: Hunter.Relationship

  @doc """
  Unfollow a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec unfollow(Hunter.Client.t(), non_neg_integer) :: Hunter.Relationship.t()
  defdelegate unfollow(conn, id), to: Hunter.Relationship

  @doc """
  Block a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec block(Hunter.Client.t(), non_neg_integer) :: Hunter.Relationship.t()
  defdelegate block(conn, id), to: Hunter.Relationship

  @doc """
  Unblock a user

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec unblock(Hunter.Client.t(), non_neg_integer) :: Hunter.Relationship.t()
  defdelegate unblock(conn, id), to: Hunter.Relationship

  @doc """
  Mute a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec mute(Hunter.Client.t(), non_neg_integer) :: Hunter.Relationship.t()
  defdelegate mute(conn, id), to: Hunter.Relationship

  @doc """
  Unmute a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec unmute(Hunter.Client.t(), non_neg_integer) :: Hunter.Relationship.t()
  defdelegate unmute(conn, id), to: Hunter.Relationship

  @doc """
  Search for content

  ## Parameters

    * `conn` - connection credentials
    * `q` - the search query
    * `options` - option list

  ## Options

    * `resolve` - whether to resolve non-local accounts

  """
  @spec search(Hunter.Client.t(), String.t(), Keyword.t()) :: Hunter.Result.t()
  defdelegate search(conn, query, options \\ []), to: Hunter.Result

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
    * `language` - ISO 639-1 language code for the status
    * `poll` - map with `options` (list of choices) and `expires_in`
      (seconds); optional: `multiple`, `hide_totals`
    * `quoted_status_id` - ID of a status to quote
    * `scheduled_at` - ISO 8601 datetime (at least 5 minutes ahead) at which
      the status should be published; the call returns a
      `Hunter.ScheduledStatus` instead of a `Hunter.Status`
    * `idempotency_key` - unique string sent as the `Idempotency-Key` header
      to prevent duplicate submissions

  """
  @spec create_status(Hunter.Client.t(), String.t(), Keyword.t()) ::
          Hunter.Status.t() | Hunter.ScheduledStatus.t() | no_return
  defdelegate create_status(conn, status, options \\ []), to: Hunter.Status

  @doc """
  Retrieve a poll

  ## Parameters

    * `conn` - connection credentials
    * `id` - poll identifier

  """
  @spec poll(Hunter.Client.t(), non_neg_integer) :: Hunter.Poll.t()
  defdelegate poll(conn, id), to: Hunter.Poll

  @doc """
  Vote on one or more options in a poll

  ## Parameters

    * `conn` - connection credentials
    * `id` - poll identifier
    * `choices` - list of option indices to vote for (zero-based)

  """
  @spec vote(Hunter.Client.t(), non_neg_integer, [non_neg_integer]) :: Hunter.Poll.t()
  defdelegate vote(conn, id, choices), to: Hunter.Poll

  @doc """
  Retrieve status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec status(Hunter.Client.t(), non_neg_integer) :: Hunter.Status.t()
  defdelegate status(conn, id), to: Hunter.Status

  @doc """
  Retrieve multiple statuses by id

  ## Parameters

    * `conn` - connection credentials
    * `ids` - list of status identifiers

  """
  @spec statuses_by_ids(Hunter.Client.t(), [non_neg_integer]) :: [Hunter.Status.t()]
  defdelegate statuses_by_ids(conn, ids), to: Hunter.Status

  @doc """
  Edit a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier
    * `status` - the new text of the status
    * `options` - option list

  ## Options

    * `spoiler_text` - text to be shown as a warning before the actual content
    * `sensitive` - whether the media of the status is NSFW
    * `language` - ISO 639-1 language code for the status
    * `media_ids` - list of media IDs to attach to the status
    * `poll` - map with `options` (list of choices) and `expires_in`
      (seconds); replaces the current poll

  """
  @spec edit_status(Hunter.Client.t(), non_neg_integer, String.t(), Keyword.t()) ::
          Hunter.Status.t() | no_return
  defdelegate edit_status(conn, id, status, options \\ []), to: Hunter.Status

  @doc """
  Retrieve the edit history of a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec status_history(Hunter.Client.t(), non_neg_integer) :: [Hunter.StatusEdit.t()]
  defdelegate status_history(conn, id), to: Hunter.Status

  @doc """
  Retrieve the plain-text source of a status, for editing

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec status_source(Hunter.Client.t(), non_neg_integer) :: Hunter.StatusSource.t()
  defdelegate status_source(conn, id), to: Hunter.Status

  @doc """
  Bookmark a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec bookmark(Hunter.Client.t(), non_neg_integer) :: Hunter.Status.t()
  defdelegate bookmark(conn, id), to: Hunter.Status

  @doc """
  Remove a status from bookmarks

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec unbookmark(Hunter.Client.t(), non_neg_integer) :: Hunter.Status.t()
  defdelegate unbookmark(conn, id), to: Hunter.Status

  @doc """
  Fetch the user's bookmarked statuses

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of bookmarks with id less than or equal this value
    * `since_id` - get a list of bookmarks with id greater than this value
    * `min_id` - get a list of bookmarks with id greater than this value,
      immediately newer
    * `limit` - maximum number of bookmarks to get, default: 20, max: 40

  """
  @spec bookmarks(Hunter.Client.t(), Keyword.t()) :: [Hunter.Status.t()]
  defdelegate bookmarks(conn, options \\ []), to: Hunter.Status

  @doc """
  Pin a status to the top of the user's profile

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec pin(Hunter.Client.t(), non_neg_integer) :: Hunter.Status.t()
  defdelegate pin(conn, id), to: Hunter.Status

  @doc """
  Unpin a status from the user's profile

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec unpin(Hunter.Client.t(), non_neg_integer) :: Hunter.Status.t()
  defdelegate unpin(conn, id), to: Hunter.Status

  @doc """
  Mute a conversation, so its thread stops generating notifications

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec mute_conversation(Hunter.Client.t(), non_neg_integer) :: Hunter.Status.t()
  defdelegate mute_conversation(conn, id), to: Hunter.Status

  @doc """
  Unmute a conversation

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec unmute_conversation(Hunter.Client.t(), non_neg_integer) :: Hunter.Status.t()
  defdelegate unmute_conversation(conn, id), to: Hunter.Status

  @doc """
  Translate a status into some language

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier
    * `options` - option list

  ## Options

    * `lang` - ISO 639-1 language code the status should be translated into;
      defaults to the user's current locale

  """
  @spec translate_status(Hunter.Client.t(), non_neg_integer, Keyword.t()) ::
          Hunter.Translation.t()
  defdelegate translate_status(conn, id, options \\ []), to: Hunter.Status

  @doc """
  Destroy status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec destroy_status(Hunter.Client.t(), non_neg_integer) :: boolean
  defdelegate destroy_status(conn, id), to: Hunter.Status

  @doc """
  Reblog a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec reblog(Hunter.Client.t(), non_neg_integer) :: Hunter.Status.t()
  defdelegate reblog(conn, id), to: Hunter.Status

  @doc """
  Undo a reblog of a status

  ## Parameters

  * `conn` - connection credentials
  * `id` - status identifier

  """
  @spec unreblog(Hunter.Client.t(), non_neg_integer) :: Hunter.Status.t()
  defdelegate unreblog(conn, id), to: Hunter.Status

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
  @spec reblogged_by(Hunter.Client.t(), non_neg_integer, Keyword.t()) :: [Hunter.Account.t()]
  defdelegate reblogged_by(conn, id, options \\ []), to: Hunter.Account

  @doc """
  Favorite a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec favourite(Hunter.Client.t(), non_neg_integer) :: Hunter.Status.t()
  defdelegate favourite(conn, id), to: Hunter.Status

  @doc """
  Undo a favorite of a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec unfavourite(Hunter.Client.t(), non_neg_integer) :: Hunter.Status.t()
  defdelegate unfavourite(conn, id), to: Hunter.Status

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
  defdelegate favourites(conn, options \\ []), to: Hunter.Status

  @doc """
  Fetch the list of users who favourited the status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier
    * `options` - option list

  ## Options

    * `max_id` - get a list of *favourited by* ids less than or equal this value
    * `since_id` - get a list of *favourited by* ids greater than this value
    * `limit` - maximum number of *favourited by* to get, default: 40, max: 80

  """

  @spec favourited_by(Hunter.Client.t(), non_neg_integer, Keyword.t()) :: [Hunter.Account.t()]
  defdelegate favourited_by(conn, id, options \\ []), to: Hunter.Account

  @doc """
  Get a list of statuses by a user

  ## Parameters

    * `conn` - connection credentials -
    * `account_id` - account identifier
    * `options` - option list

  ## Options

    * `only_media` - only return `Hunter.Status.t` that have media attachments
    * `exclude_replies` - skip statuses that reply to other statuses
    * `max_id` - get a list of statuses with id less than or equal this value
    * `since_id` - get a list of statuses with id greater than this value
    * `limit` - maximum number of statuses to get, default: 20, max: 40

  """
  @spec statuses(Hunter.Client.t(), non_neg_integer, Keyword.t()) :: [Hunter.Status.t()]
  defdelegate statuses(conn, account_id, options \\ []), to: Hunter.Status

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
  defdelegate home_timeline(conn, options \\ []), to: Hunter.Status

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
  defdelegate public_timeline(conn, options \\ []), to: Hunter.Status

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
  defdelegate hashtag_timeline(conn, hashtag, options \\ []), to: Hunter.Status

  @doc """
  Retrieve instance information

  ## Parameters

    * `conn` - connection credentials

  """
  @spec instance_info(Hunter.Client.t()) :: Hunter.Instance.t()
  defdelegate instance_info(conn), to: Hunter.Instance

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
  @spec notifications(Hunter.Client.t(), Keyword.t()) :: [Hunter.Notification.t()]
  defdelegate notifications(conn, options \\ []), to: Hunter.Notification

  @doc """
  Retrieve single notification

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification identifier

  """
  @spec notification(Hunter.Client.t(), non_neg_integer) :: Hunter.Notification.t()
  defdelegate notification(conn, id), to: Hunter.Notification

  @doc """
  Deletes all notifications from the Mastodon server for the authenticated user

  ## Parameters

    * `conn` - connection credentials

  """
  @spec clear_notifications(Hunter.Client.t()) :: boolean
  defdelegate clear_notifications(conn), to: Hunter.Notification

  @doc """
  Dismiss a single notification

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification id

  """
  @spec clear_notification(Hunter.Client.t(), non_neg_integer) :: boolean
  defdelegate clear_notification(conn, id), to: Hunter.Notification

  @doc """
  Report a user

  ## Parameters

    * `conn` - connection credentials
    * `account_id` - the ID of the account to report
    * `status_ids` - the IDs of statuses to report
    * `comment` - a comment to associate with the report

  """
  @spec report(Hunter.Client.t(), non_neg_integer, [non_neg_integer], String.t()) ::
          Hunter.Report.t()
  defdelegate report(conn, account_id, status_ids, comment), to: Hunter.Report

  @doc """
  Retrieve status context

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec status_context(Hunter.Client.t(), non_neg_integer) :: Hunter.Context.t()
  defdelegate status_context(conn, id), to: Hunter.Context

  @doc """
  Retrieve access token

  ## Parameters

    * `app` - application details, see: `Hunter.Application.create_app/5` for more details.
    * `username` - account's email
    * `password` - account's password
    * `base_url` - API base url, default: `https://mastodon.social`

  """
  @spec log_in(Hunter.Application.t(), String.t(), String.t(), String.t()) :: Hunter.Client.t()
  defdelegate log_in(app, username, password, base_url \\ "https://mastodon.social"),
    to: Hunter.Client

  @doc """
  Retrieve access token via OAuth

  ## Parameters
    * `app` - application details, see: `Hunter.Application.create_app/5` for more details.
    * `oauth_code` - OAuth authentication code
    * `base_url` - API base url, default: `https://mastodon.social`
  """
  @spec log_in_oauth(Hunter.Application.t(), String.t(), String.t()) :: Hunter.Client.t()
  defdelegate log_in_oauth(app, oauth_code, base_url \\ "https://mastodon.social"),
    to: Hunter.Client

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
  defdelegate blocked_domains(conn, options \\ []), to: Hunter.Domain

  @doc """
  Block a domain

  ## Parameters

    * `conn` - connection credentials
    * `domain` - domain to block

  """
  @spec block_domain(Hunter.Client.t(), String.t()) :: boolean()
  defdelegate block_domain(conn, domain), to: Hunter.Domain

  @doc """
  Unblock a domain

  ## Parameters

    * `conn` - connection credentials
    * `domain` - domain to unblock

  """
  @spec unblock_domain(Hunter.Client.t(), String.t()) :: boolean()
  defdelegate unblock_domain(conn, domain), to: Hunter.Domain

  @doc """
  Returns Hunter version
  """
  @spec version() :: String.t()
  def version, do: @hunter_version
end
