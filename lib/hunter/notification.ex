defmodule Hunter.Notification do
  @moduledoc """
  Notification entity

  This module defines a `Hunter.Notification` struct and the main functions
  for working with Notifications.

  ## Fields

    * `id` - The notification ID
    * `type` - One of: "mention", "reblog", "favourite", "follow"
    * `created_at` - The time the notification was created
    * `account` - The `Hunter.Account` sending the notification to the user
    * `status` - The `Hunter.Status` associated with the notification, if applicable

  """
  alias Hunter.Config

  @type t :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          created_at: String.t(),
          account: Hunter.Account.t(),
          status: Hunter.Status.t()
        }

  @derive [Poison.Encoder]
  defstruct [:id, :type, :created_at, :account, :status]

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
    Config.hunter_api().notifications(conn, options)
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
  @spec notification(Hunter.Client.t(), non_neg_integer) :: Hunter.Notification.t()
  def notification(conn, id) do
    Config.hunter_api().notification(conn, id)
  end

  @doc """
  Deletes all notifications from the Mastodon server for the authenticated user

  ## Parameters

    * `conn` - connection credentials

  """
  @spec clear_notifications(Hunter.Client.t()) :: boolean
  def clear_notifications(conn) do
    Config.hunter_api().clear_notifications(conn)
  end

  @doc """
  Dismiss a single notification

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification id

  """
  @spec clear_notification(Hunter.Client.t(), non_neg_integer) :: boolean
  def clear_notification(conn, id) do
    Config.hunter_api().clear_notification(conn, id)
  end
end
