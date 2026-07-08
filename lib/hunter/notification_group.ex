defmodule Hunter.NotificationGroup do
  @moduledoc """
  NotificationGroup entity

  A group of related notifications, as returned by the grouped
  notifications API

  ## Fields

    * `group_key` - group key identifying the grouped notifications; should
      be treated as an opaque value
    * `notifications_count` - total number of individual notifications that
      are part of this group
    * `type` - the type of event that resulted in the notifications, same
      values as `Hunter.Notification` types
    * `most_recent_notification_id` - ID of the most recent notification in
      the group
    * `page_min_id` - ID of the oldest notification from this group
      represented within the current page
    * `page_max_id` - ID of the newest notification from this group
      represented within the current page
    * `latest_page_notification_at` - date at which the most recent
      notification within the current page was created
    * `sample_account_ids` - IDs of some of the accounts who most recently
      triggered notifications in this group
    * `status_id` - ID of the `Hunter.Status` that was the object of the
      notification, if applicable
    * `report` - the report that was the object of the notification, for
      `admin.report` notifications
    * `event` - summary of the event that caused follow relationships to be
      severed, for `severed_relationships` notifications
    * `moderation_warning` - the moderation warning that caused the
      notification, for `moderation_warning` notifications

  """

  @type t :: %__MODULE__{
          group_key: String.t(),
          notifications_count: non_neg_integer,
          type: String.t(),
          most_recent_notification_id: String.t(),
          page_min_id: String.t() | nil,
          page_max_id: String.t() | nil,
          latest_page_notification_at: String.t() | nil,
          sample_account_ids: [String.t()],
          status_id: String.t() | nil,
          report: Hunter.Report.t() | nil,
          event: map | nil,
          moderation_warning: map | nil
        }

  @derive [Poison.Encoder]
  defstruct [
    :group_key,
    :notifications_count,
    :type,
    :most_recent_notification_id,
    :page_min_id,
    :page_max_id,
    :latest_page_notification_at,
    :sample_account_ids,
    :status_id,
    :report,
    :event,
    :moderation_warning
  ]
end
