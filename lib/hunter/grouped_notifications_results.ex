defmodule Hunter.GroupedNotificationsResults do
  @moduledoc """
  GroupedNotificationsResults entity

  The response of the grouped notifications API: the notification groups
  plus the accounts and statuses they reference, deduplicated

  ## Fields

    * `accounts` - list of `Hunter.Account` referenced by the groups
    * `partial_accounts` - partial account representations, only returned
      when requesting `expand_accounts=partial_avatars`
    * `statuses` - list of `Hunter.Status` referenced by the groups
    * `notification_groups` - list of `Hunter.NotificationGroup`

  """

  @type t :: %__MODULE__{
          accounts: [Hunter.Account.t()],
          partial_accounts: [map] | nil,
          statuses: [Hunter.Status.t()],
          notification_groups: [Hunter.NotificationGroup.t()]
        }

  @derive [Poison.Encoder]
  defstruct [:accounts, :partial_accounts, :statuses, :notification_groups]
end
