defmodule Hunter.Account do
  @moduledoc """
  Account entity

  This module defines a `Hunter.Account` struct and the main functions
  for working with Accounts.

  ## Fields

    * `id` - the ID of the account
    * `username` - the username of the account
    * `acct` - equals `username` for local users, includes `@domain` for remote ones
    * `display_name` - the account's display name
    * `note` - Biography of user
    * `url` - URL of the user's profile page (can be remote)
    * `avatar` - URL to the avatar image
    * `header` - URL to the header image
    * `locked` - boolean for when the account cannot be followed without waiting for approval first
    * `created_at` - the time the account was created
    * `followers_count` - the number of followers for the account
    * `following_count` - the number of accounts the given account is following
    * `statuses_count` - the number of statuses the account has made

  """
  @hunter_api Application.get_env(:hunter, :hunter_api)

  @type t :: %__MODULE__{
    id: non_neg_integer,
    username: String.t,
    acct: String.t,
    display_name: String.t,
    note: String.t,
    url: URI.t,
    avatar: URI.t,
    header: URI.t,
    locked: String.t,
    created_at: String.t,
    followers_count: non_neg_integer,
    following_count: non_neg_integer,
    statuses_count: non_neg_integer
  }

  @derive [Poison.Encoder]
  defstruct [:id,
            :username,
            :acct,
            :display_name,
            :note,
            :url,
            :avatar,
            :header,
            :locked,
            :created_at,
            :followers_count,
            :following_count,
            :statuses_count]


  @doc """
  Retrieve account of authenticated user

  ## Parameters

    * `conn` - Connection credentials

  """
  @spec verify_credentials(Hunter.Client.t) :: Hunter.Account.t
  def verify_credentials(conn) do
    @hunter_api.verify_credentials(conn)
  end

  @doc """
  Retrieve account

  ## Parameters

    * `conn` - Connection credentials
    * `id`

  """
  @spec account(Hunter.Client.t, non_neg_integer) :: Hunter.Account.t
  def account(conn, id) do
    @hunter_api.account(conn, id)
  end

  @doc """
  Get a list of followers

  ## Parameters

    * `conn` - Connection credentials
    * `id`

  """
  @spec followers(Hunter.Client.t, non_neg_integer) :: [Hunter.Account.t]
  def followers(conn, id) do
    @hunter_api.followers(conn, id)
  end

  @doc """
  Get a list of followed accounts

  ## Parameters

    * `conn` - Connection credentials
    * `id`

  """
  @spec following(Hunter.Client.t, non_neg_integer) :: [Hunter.Account.t]
  def following(conn, id) do
    @hunter_api.following(conn, id)
  end

  @doc """
  Follow a remote user

  ## Parameters

    * `conn` - Connection credentials
    * `uri` - URI of the remote user, in the format of username@domain

  """
  @spec follow_by_uri(Hunter.Client.t, URI.t) :: Hunter.Account.t
  def follow_by_uri(conn, uri) do
    @hunter_api.follow_by_uri(conn, uri)
  end
end
