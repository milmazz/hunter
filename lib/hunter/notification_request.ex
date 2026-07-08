defmodule Hunter.NotificationRequest do
  @moduledoc """
  NotificationRequest entity

  Represents a group of filtered notifications from a specific user

  ## Fields

    * `id` - the ID of the notification request
    * `created_at` - when the first filtered notification from that user was
      created
    * `updated_at` - when the notification request was last updated
    * `account` - the `Hunter.Account` that performed the actions being
      filtered
    * `notifications_count` - how many of this account's notifications were
      filtered, as a string
    * `last_status` - the most recent `Hunter.Status` associated with a
      filtered notification from the account, if any

  """

  @type t :: %__MODULE__{
          id: String.t(),
          created_at: String.t(),
          updated_at: String.t(),
          account: Hunter.Account.t(),
          notifications_count: String.t(),
          last_status: Hunter.Status.t() | nil
        }

  @derive [Poison.Encoder]
  defstruct [:id, :created_at, :updated_at, :account, :notifications_count, :last_status]
end
