defmodule Hunter.Relationship do
  @moduledoc """
  Relationship entity

  This module defines a `Hunter.Relationship` struct.

  ## Fields

    * `id` - target account id
    * `following` - whether the user is currently following the account
    * `showing_reblogs` - whether boosts from this account are shown in the home timeline
    * `notifying` - whether the user has enabled notifications for this account
    * `languages` - which languages the user is following this account for, if any
    * `followed_by` - whether the user is currently being followed by the account
    * `blocking` - whether the user is currently blocking the account
    * `blocked_by` - whether the account is currently blocking the user
    * `muting` - whether the user is currently muting the account
    * `muting_notifications` - whether the user is muting notifications from the account
    * `muting_expires_at` - when the mute expires, if the mute is temporary
    * `requested` - whether the user has requested to follow the account
    * `requested_by` - whether the account has requested to follow the user
    * `domain_blocking` - whether the user is currently blocking the user's domain
    * `endorsed` - whether the user is featuring the account on their profile
    * `note` - the user's private comment on the account

  """

  @type t :: %__MODULE__{
          id: String.t(),
          following: boolean,
          showing_reblogs: boolean,
          notifying: boolean,
          languages: [String.t()] | nil,
          followed_by: boolean,
          blocking: boolean,
          blocked_by: boolean,
          muting: boolean,
          muting_notifications: boolean,
          muting_expires_at: String.t() | nil,
          requested: boolean,
          requested_by: boolean,
          domain_blocking: boolean,
          endorsed: boolean,
          note: String.t()
        }

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :following,
    :showing_reblogs,
    :notifying,
    :languages,
    :followed_by,
    :blocking,
    :blocked_by,
    :muting,
    :muting_notifications,
    :muting_expires_at,
    :requested,
    :requested_by,
    :domain_blocking,
    :endorsed,
    :note
  ]
end
