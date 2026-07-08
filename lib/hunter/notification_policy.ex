defmodule Hunter.NotificationPolicy do
  @moduledoc """
  NotificationPolicy entity

  The filtering policy for notifications; each `for_*` field takes one of
  `accept`, `filter` or `drop`

  ## Fields

    * `for_not_following` - policy for accounts the user is not following
    * `for_not_followers` - policy for accounts not following the user
    * `for_new_accounts` - policy for accounts created in the past 30 days
    * `for_private_mentions` - policy for private mentions
    * `for_limited_accounts` - policy for accounts limited by a moderator
    * `summary` - map with `pending_requests_count` (number of accounts with
      non-dismissed filtered notifications, capped at 100) and
      `pending_notifications_count` keys

  """

  @type t :: %__MODULE__{
          for_not_following: String.t(),
          for_not_followers: String.t(),
          for_new_accounts: String.t(),
          for_private_mentions: String.t(),
          for_limited_accounts: String.t(),
          summary: map
        }

  @derive [Poison.Encoder]
  defstruct [
    :for_not_following,
    :for_not_followers,
    :for_new_accounts,
    :for_private_mentions,
    :for_limited_accounts,
    :summary
  ]
end
