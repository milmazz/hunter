defmodule Hunter.Account do
  @moduledoc """
  Account entity

  This module defines a `Hunter.Account` struct and the main functions
  for working with Accounts.

  ## Fields

    * `id` - the account id
    * `username` - the username of the account
    * `acct` - equals `username` for local users, includes `@domain` for remote ones
    * `display_name` - the account's display name
    * `note` - biography of user
    * `url` - URL of the user's profile page (can be remote)
    * `avatar` - URL to the avatar image
    * `avatar_static` - URL to the avatar static image (gif)
    * `header` - URL to the header image
    * `header_static` - URL to the header static image (gif)
    * `locked` - boolean for when the account cannot be followed without waiting for approval first
    * `created_at` - the time the account was created
    * `followers_count` - the number of followers for the account
    * `following_count` - the number of accounts the given account is following
    * `statuses_count` - the number of statuses the account has made

  """
  @hunter_api Hunter.Config.hunter_api()

  @type t :: %__MODULE__{
    id: non_neg_integer,
    username: String.t,
    acct: String.t,
    display_name: String.t,
    note: String.t,
    url: String.t,
    avatar: String.t,
    avatar_static: String.t,
    header: String.t,
    header_static: String.t,
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
            :avatar_static,
            :header,
            :header_static,
            :locked,
            :created_at,
            :followers_count,
            :following_count,
            :statuses_count]

  @doc """
  Retrieve account of authenticated user

  ## Parameters

    * `conn` - connection credentials

  ## Examples

        iex> conn = Hunter.new([base_url: "https://social.lou.lt", bearer_token: "123456"])
        %Hunter.Client{base_url: "https://social.lou.lt", bearer_token: "123456"}
        iex> Hunter.Account.verify_credentials(conn)
        %Hunter.Account{acct: "milmazz",
                avatar: "https://social.lou.lt/avatars/original/missing.png",
                avatar_static: "https://social.lou.lt/avatars/original/missing.png",
                created_at: "2017-04-06T17:43:55.325Z",
                display_name: "Milton Mazzarri", followers_count: 4,
                following_count: 4,
                header: "https://social.lou.lt/headers/original/missing.png",
                header_static: "https://social.lou.lt/headers/original/missing.png",
                id: 8039, locked: false, note: "", statuses_count: 3,
                url: "https://social.lou.lt/@milmazz", username: "milmazz"}

  """
  @spec verify_credentials(Hunter.Client.t) :: Hunter.Account.t
  def verify_credentials(conn) do
    @hunter_api.verify_credentials(conn)
  end

  @doc """
  Make changes to the authenticated user

  ## Parameters

    * `conn` - connection credentials
    * `data` - data payload

  ## Possible keys for payload

    * `display_name` - name to display in the user's profile
    * `note` - new biography for the user
    * `avatar` - base64 encoded image to display as the user's avatar (e.g. `data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAUoAAADrCAYAAAA...`)
    * `header` - base64 encoded image to display as the user's header image (e.g. `data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAUoAAADrCAYAAAA...`)

  """
  @spec update_credentials(Hunter.Client.t, map) :: Hunter.Account.t
  def update_credentials(conn, data) do
    @hunter_api.update_credentials(conn, data)
  end

  @doc """
  Retrieve account

  ## Parameters

    * `conn` - connection credentials
    * `id` - account id

  """
  @spec account(Hunter.Client.t, non_neg_integer) :: Hunter.Account.t
  def account(conn, id) do
    @hunter_api.account(conn, id)
  end

  @doc """
  Get a list of followers

  ## Parameters

    * `conn` - connection credentials
    * `id` - account id
    * `options` - options list

  ## Options

    * `max_id` - get a list of followers with id less than or equal this value
    * `since_id` - get a list of followers with id greater than this value
    * `limit` - maximum number of followers to get, default: 40, maximum: 80

  """
  @spec followers(Hunter.Client.t, non_neg_integer, Keyword.t) :: [Hunter.Account.t]
  def followers(conn, id, options \\ []) do
    @hunter_api.followers(conn, id, options)
  end

  @doc """
  Get a list of followed accounts

  ## Parameters

    * `conn` - connection credentials
    * `id` - account id
    * `options` - options list

  ## Options

    * `max_id` - get a list of followings with id less than or equal this value
    * `since_id` - get a list of followings with id greater than this value
    * `limit` - maximum number of followings to get, default: 40, maximum: 80

  """
  @spec following(Hunter.Client.t, non_neg_integer, Keyword.t) :: [Hunter.Account.t]
  def following(conn, id, options \\ []) do
    @hunter_api.following(conn, id, options)
  end

  @doc """
  Follow a remote user

  ## Parameters

    * `conn` - connection credentials
    * `uri` - URI of the remote user, in the format of `username@domain`

  """
  @spec follow_by_uri(Hunter.Client.t, String.t) :: Hunter.Account.t
  def follow_by_uri(conn, uri) do
    @hunter_api.follow_by_uri(conn, uri)
  end

  @doc """
  Search for accounts

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `q`: what to search for
    * `limit`: maximum number of matching accounts to return, default: 40

  """
  @spec search_account(Hunter.Client.t, Keyword.t) :: [Hunter.Account.t]
  def search_account(conn, options) do
    opts = %{
      q: Keyword.fetch!(options, :q),
      limit: Keyword.get(options, :limit, 40)
    }

    @hunter_api.search_account(conn, opts)
  end

  @doc """
  Retrieve user's blocks

  ## Parameters

    * `conn` - connection credentials

  ## Options

    * `max_id` - get a list of blocks with id less than or equal this value
    * `since_id` - get a list of blocks with id greater than this value
    * `limit` - maximum number of blocks to get, default: 40, max: 80

  """
  @spec blocks(Hunter.Client.t, Keyword.t) :: [Hunter.Account.t]
  def blocks(conn, options \\ []) do
    @hunter_api.blocks(conn, options)
  end

  @doc """
  Retrieve a list of follow requests

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of follow requests with id less than or equal this value
    * `since_id` - get a list of follow requests with id greater than this value
    * `limit` - maximum number of requests to get, default: 40, max: 80

  """
  @spec follow_requests(Hunter.Client.t, Keyword.t) :: [Hunter.Account.t]
  def follow_requests(conn, options \\ []) do
    @hunter_api.follow_requests(conn, options)
  end

  @doc """
  Retrieve user's mutes

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of mutes with id less than or equal this value
    * `since_id` - get a list of mutes with id greater than this value
    * `limit` - maximum number of mutes to get, default: 40, max: 80

  """
  @spec mutes(Hunter.Client.t, Keyword.t) :: [Hunter.Account.t]
  def mutes(conn, options \\ []) do
    @hunter_api.mutes(conn, options)
  end

  @doc """
  Accepts a follow request

  ## Parameters

    * `conn` - connection credentials
    * `id` - follow request id

  """
  @spec accept_follow_request(Hunter.Client.t, non_neg_integer) :: boolean
  def accept_follow_request(conn, id) do
    @hunter_api.follow_request_action(conn, id, :authorize)
  end

  @doc """
  Rejects a follow request

  ## Parameters

    * `conn` - connection credentials
    * `id` - follow request id

  """
  @spec reject_follow_request(Hunter.Client.t, non_neg_integer) :: boolean
  def reject_follow_request(conn, id) do
    @hunter_api.follow_request_action(conn, id, :reject)
  end

  @doc """
  Fetch the list of users who reblogged the status.

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier
    * `options` - option list

  ## Options

    * `max_id` - get a list of *reblogged by* ids less than or equal this value
    * `since_id` - get a list of *reblogged by* ids greater than this value
    * `limit` - maximum number of *reblogged by* to get, default: 40, max: 80

  """
  @spec reblogged_by(Hunter.Client.t, non_neg_integer, Keyword.t) :: [Hunter.Account.t]
  def reblogged_by(conn, id, options \\ []) do
    @hunter_api.reblogged_by(conn, id, options)
  end

  @doc """
  Fetch the list of users who favourited the status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier
    * `options` - option list

  ## Options

    * `max_id` - get a list of *favourited by* ids less than or equal this value
    * `since_id` - get a list of *favourited by* ids greater than this value
    * `limit` - maximum number of *favourited by* to get, default: 40, max: 80

  """

  @spec favourited_by(Hunter.Client.t, non_neg_integer, Keyword.t) :: [Hunter.Account.t]
  def favourited_by(conn, id, options \\ []) do
    @hunter_api.favourited_by(conn, id, options)
  end
end
