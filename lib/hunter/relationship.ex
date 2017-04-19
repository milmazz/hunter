defmodule Hunter.Relationship do
  @moduledoc """
  Relationship entity

  This module defines a `Hunter.Relationship` struct and the main functions
  for working with Relationship.

  ## Fields

    * `following` - Whether the user is currently following the account
    * `followed_by` - Whether the user is currently being followed by the account
    * `blocking` - Whether the user is currently blocking the account
    * `muting` - Whether the user is currently muting the account
    * `requested` - Whether the user has requested to follow the account

  """
  @hunter_api Hunter.Config.hunter_api()

  @type t :: %__MODULE__{
    following: boolean,
    followed_by: boolean,
    blocking: boolean,
    muting: boolean,
    requested: boolean
  }

  @derive [Poison.Encoder]
  defstruct [:following, :followed_by, :blocking, :muting, :requested]

  @doc """
  Get the relationships of authenticated user towards given other users

  ## Parameters

    * `conn` - connection credentials
    * `id` - list of relationship IDs

  """
  @spec relationships(Hunter.Client.t, [non_neg_integer]) :: [Hunter.Relationship.t]
  def relationships(conn, ids) do
    @hunter_api.relationships(conn, ids)
  end

  @doc """
  Follow a user

  ## Parameters

    * `conn` - Connection credentials
    * `id` - user id

  """
  @spec follow(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  def follow(conn, id) do
    @hunter_api.follow(conn, id)
  end

  @doc """
  Unfollow a user

  ## Parameters

    * `conn` - Connection credentials
    * `id` - user id

  """
  @spec unfollow(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  def unfollow(conn, id) do
    @hunter_api.unfollow(conn, id)
  end

  @doc """
  Block a user

  ## Parameters

    * `conn` - Connection credentials
    * `id` - user id

  """
  @spec block(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  def block(conn, id) do
    @hunter_api.block(conn, id)
  end

  @doc """
  Unblock a user

    * `conn` - Connection credentials
    * `id` - user id

  """
  @spec unblock(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  def unblock(conn, id) do
    @hunter_api.unblock(conn, id)
  end

  @doc """
  Mute a user

  ## Parameters

    * `conn` - Connection credentials
    * `id` - user id

  """
  @spec mute(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  def mute(conn, id) do
    @hunter_api.mute(conn, id)
  end

  @doc """
  Unmute a user

  ## Parameters

    * `conn` - Connection credentials
    * `id` - user id

  """
  @spec unmute(Hunter.Client.t, non_neg_integer) :: Hunter.Relationship.t
  def unmute(conn, id) do
    @hunter_api.unmute(conn, id)
  end
end
