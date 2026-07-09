defmodule Hunter.Notification do
  @moduledoc """
  Notification entity

  This module defines a `Hunter.Notification` struct and the main functions
  for working with Notifications.

  ## Fields

    * `id` - The notification ID
    * `type` - One of: "mention", "status", "reblog", "follow", "follow_request",
      "favourite", "poll", "update", "admin.sign_up", "admin.report",
      "severed_relationships", "moderation_warning", "quote", "quoted_update"
    * `created_at` - The time the notification was created
    * `group_key` - Group key shared by similar notifications, used by
      grouped notifications
    * `account` - The `Hunter.Account` sending the notification to the user
    * `status` - The `Hunter.Status` associated with the notification, if applicable
    * `report` - The `Hunter.Report` associated with an "admin.report" notification
    * `event` - Summary of the event that caused a "severed_relationships"
      notification, if applicable
    * `moderation_warning` - The moderation warning that caused a
      "moderation_warning" notification, if applicable

  """
  alias Hunter.Api.HTTPClient

  @type t :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          created_at: String.t(),
          group_key: String.t() | nil,
          account: Hunter.Account.t(),
          status: Hunter.Status.t(),
          report: Hunter.Report.t() | nil,
          event: map | nil,
          moderation_warning: map | nil
        }

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :type,
    :created_at,
    :group_key,
    :account,
    :status,
    :report,
    :event,
    :moderation_warning
  ]

  @doc """
  Retrieve user's notifications

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of notifications with id less than or equal this value
    * `since_id` - get a list of notifications with id greater than this value
    * `limit` - maximum number of notifications to get, default: 15, max: 30

  ## Examples

      Hunter.Notification.notifications(conn)
      #=> [%Hunter.Notification{account: %{"acct" => "paperswelove@mstdn.io", ...}]

  """
  @spec notifications(Hunter.Client.t(), Keyword.t()) :: [Hunter.Notification.t()]
  def notifications(conn, options \\ []) do
    HTTPClient.notifications(conn, options)
  end

  @doc """
  Retrieve single notification

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification identifier

  ## Examples

      Hunter.Notification.notification(conn, 17_476)
      #=> %Hunter.Notification{account: %{"acct" => "paperswelove@mstdn.io", ...}

  """
  @spec notification(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Notification.t()
  def notification(conn, id) do
    HTTPClient.notification(conn, id)
  end

  @doc """
  Deletes all notifications from the Mastodon server for the authenticated user

  ## Parameters

    * `conn` - connection credentials

  """
  @spec clear_notifications(Hunter.Client.t()) :: boolean
  def clear_notifications(conn) do
    HTTPClient.clear_notifications(conn)
  end

  @doc """
  Dismiss a single notification

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification id

  """
  @spec clear_notification(Hunter.Client.t(), String.t() | non_neg_integer) :: boolean
  def clear_notification(conn, id) do
    HTTPClient.clear_notification(conn, id)
  end

  @doc """
  Retrieve the number of unread notifications, capped by the server

  ## Parameters

    * `conn` - connection credentials

  """
  @spec unread_count(Hunter.Client.t()) :: non_neg_integer
  def unread_count(conn) do
    HTTPClient.unread_count(conn)
  end

  @doc """
  Retrieve the notification filtering policy for the user

  ## Parameters

    * `conn` - connection credentials

  """
  @spec notification_policy(Hunter.Client.t()) :: Hunter.NotificationPolicy.t()
  def notification_policy(conn) do
    HTTPClient.notification_policy(conn)
  end

  @doc """
  Update the notification filtering policy for the user

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

  Each takes one of `accept`, `filter` or `drop`:

    * `for_not_following`
    * `for_not_followers`
    * `for_new_accounts`
    * `for_private_mentions`
    * `for_limited_accounts`

  """
  @spec update_notification_policy(Hunter.Client.t(), Keyword.t()) ::
          Hunter.NotificationPolicy.t()
  def update_notification_policy(conn, options) do
    HTTPClient.update_notification_policy(conn, options)
  end

  @doc """
  Retrieve notification requests (groups of filtered notifications)

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get requests with id less than or equal this value
    * `since_id` - get requests with id greater than this value
    * `limit` - maximum number of requests to get, default: 40, max: 80

  """
  @spec notification_requests(Hunter.Client.t(), Keyword.t()) :: [
          Hunter.NotificationRequest.t()
        ]
  def notification_requests(conn, options \\ []) do
    HTTPClient.notification_requests(conn, options)
  end

  @doc """
  Retrieve a single notification request

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification request identifier

  """
  @spec notification_request(Hunter.Client.t(), String.t() | non_neg_integer) ::
          Hunter.NotificationRequest.t()
  def notification_request(conn, id) do
    HTTPClient.notification_request(conn, id)
  end

  @doc """
  Accept a notification request, so future notifications from the account
  are delivered normally

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification request identifier

  """
  @spec accept_notification_request(Hunter.Client.t(), String.t() | non_neg_integer) :: boolean
  def accept_notification_request(conn, id) do
    HTTPClient.accept_notification_request(conn, id)
  end

  @doc """
  Dismiss a notification request, removing it and its filtered notifications

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification request identifier

  """
  @spec dismiss_notification_request(Hunter.Client.t(), String.t() | non_neg_integer) :: boolean
  def dismiss_notification_request(conn, id) do
    HTTPClient.dismiss_notification_request(conn, id)
  end

  @doc """
  Accept multiple notification requests

  ## Parameters

    * `conn` - connection credentials
    * `ids` - notification request identifiers

  """
  @spec accept_notification_requests(Hunter.Client.t(), [String.t() | non_neg_integer]) ::
          boolean
  def accept_notification_requests(conn, ids) do
    HTTPClient.accept_notification_requests(conn, ids)
  end

  @doc """
  Dismiss multiple notification requests

  ## Parameters

    * `conn` - connection credentials
    * `ids` - notification request identifiers

  """
  @spec dismiss_notification_requests(Hunter.Client.t(), [String.t() | non_neg_integer]) ::
          boolean
  def dismiss_notification_requests(conn, ids) do
    HTTPClient.dismiss_notification_requests(conn, ids)
  end

  @doc """
  Check whether accepted notification requests have been merged into the
  main notification list

  ## Parameters

    * `conn` - connection credentials

  """
  @spec notification_requests_merged?(Hunter.Client.t()) :: boolean
  def notification_requests_merged?(conn) do
    HTTPClient.notification_requests_merged?(conn)
  end

  @doc """
  Retrieve grouped notifications, together with the accounts and statuses
  they reference

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get groups with id less than or equal this value
    * `since_id` - get groups with id greater than this value
    * `limit` - maximum number of groups to get, default: 40, max: 80
    * `types` - notification types to include
    * `exclude_types` - notification types to exclude
    * `grouped_types` - which types can be grouped together

  """
  @spec grouped_notifications(Hunter.Client.t(), Keyword.t()) ::
          Hunter.GroupedNotificationsResults.t()
  def grouped_notifications(conn, options \\ []) do
    HTTPClient.grouped_notifications(conn, options)
  end

  @doc """
  Retrieve a single notification group by its group key

  ## Parameters

    * `conn` - connection credentials
    * `group_key` - notification group key

  """
  @spec notification_group(Hunter.Client.t(), String.t()) ::
          Hunter.GroupedNotificationsResults.t()
  def notification_group(conn, group_key) do
    HTTPClient.notification_group(conn, group_key)
  end

  @doc """
  Dismiss a notification group

  ## Parameters

    * `conn` - connection credentials
    * `group_key` - notification group key

  """
  @spec dismiss_notification_group(Hunter.Client.t(), String.t()) :: boolean
  def dismiss_notification_group(conn, group_key) do
    HTTPClient.dismiss_notification_group(conn, group_key)
  end

  @doc """
  Retrieve the accounts of all notifications in a notification group

  ## Parameters

    * `conn` - connection credentials
    * `group_key` - notification group key

  """
  @spec notification_group_accounts(Hunter.Client.t(), String.t()) :: [Hunter.Account.t()]
  def notification_group_accounts(conn, group_key) do
    HTTPClient.notification_group_accounts(conn, group_key)
  end

  @doc """
  Retrieve the number of unread notification groups, capped by the server

  ## Parameters

    * `conn` - connection credentials

  """
  @spec grouped_unread_count(Hunter.Client.t()) :: non_neg_integer
  def grouped_unread_count(conn) do
    HTTPClient.grouped_unread_count(conn)
  end
end
