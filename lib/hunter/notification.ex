defmodule Hunter.Notification do
  @moduledoc """
  Notification entity

  This module defines a `Hunter.Notification` struct.

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
end
