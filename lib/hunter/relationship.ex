defmodule Hunter.Relationship do
  @moduledoc """
  Relationship entity

  This module defines a `Hunter.Relationship` struct and the main functions
  for working with Relationship.

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
  alias Hunter.Api.HTTPClient

  @type t :: %__MODULE__{
          id: non_neg_integer,
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

  @doc """
  Get the relationships of authenticated user towards given other users

  ## Parameters

    * `conn` - connection credentials
    * `id` - list of relationship IDs

  """
  @spec relationships(Hunter.Client.t(), [non_neg_integer]) :: [Hunter.Relationship.t()]
  def relationships(conn, ids) do
    HTTPClient.relationships(conn, ids)
  end

  @doc """
  Follow a user

  ## Parameters

    * `conn` - Connection credentials
    * `id` - user id

  """
  @spec follow(Hunter.Client.t(), non_neg_integer) :: Hunter.Relationship.t()
  def follow(conn, id) do
    HTTPClient.follow(conn, id)
  end

  @doc """
  Unfollow a user

  ## Parameters

    * `conn` - Connection credentials
    * `id` - user id

  """
  @spec unfollow(Hunter.Client.t(), non_neg_integer) :: Hunter.Relationship.t()
  def unfollow(conn, id) do
    HTTPClient.unfollow(conn, id)
  end

  @doc """
  Block a user

  ## Parameters

    * `conn` - Connection credentials
    * `id` - user id

  """
  @spec block(Hunter.Client.t(), non_neg_integer) :: Hunter.Relationship.t()
  def block(conn, id) do
    HTTPClient.block(conn, id)
  end

  @doc """
  Unblock a user

    * `conn` - Connection credentials
    * `id` - user id

  """
  @spec unblock(Hunter.Client.t(), non_neg_integer) :: Hunter.Relationship.t()
  def unblock(conn, id) do
    HTTPClient.unblock(conn, id)
  end

  @doc """
  Mute a user

  ## Parameters

    * `conn` - Connection credentials
    * `id` - user id

  """
  @spec mute(Hunter.Client.t(), non_neg_integer) :: Hunter.Relationship.t()
  def mute(conn, id) do
    HTTPClient.mute(conn, id)
  end

  @doc """
  Unmute a user

  ## Parameters

    * `conn` - Connection credentials
    * `id` - user id

  """
  @spec unmute(Hunter.Client.t(), non_neg_integer) :: Hunter.Relationship.t()
  def unmute(conn, id) do
    HTTPClient.unmute(conn, id)
  end
end
