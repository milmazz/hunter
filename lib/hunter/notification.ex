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
  @type t :: %__MODULE__{
    id: String.t,
    type: String.t,
    created_at: String.t,
    account: Hunter.Account.t,
    status: Hunter.Status.t
  }

  @derive [Poison.Encoder]
  defstruct [:id, :type, :created_at, :account, :status]
end
