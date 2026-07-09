defmodule Hunter.Account do
  @moduledoc """
  Account entity

  This module defines a `Hunter.Account` struct and the main functions
  for working with Accounts.

  ## Fields

    * `id` - the id of the account
    * `username` - the username of the account
    * `acct` - equals `username` for local users, includes `@domain` for remote ones
    * `display_name` - the account's display name
    * `locked` - boolean for when the account cannot be followed without waiting for approval first
    * `created_at` - the time the account was created
    * `followers_count` - the number of followers for the account
    * `following_count` - the number of accounts the given account is following
    * `statuses_count` - the number of statuses the account has made
    * `note` - biography of user
    * `url` - URL of the user's profile page (can be remote)
    * `avatar` - URL to the avatar image
    * `avatar_static` - URL to the avatar static image (gif)
    * `header` - URL to the header image
    * `header_static` - URL to the header static image (gif)
    * `emojis` - list of emojis
    * `moved` - moved from account
    * `fields` - list of `Hunter.Field`, additional profile metadata
    * `bot` - whether this account is a bot or not
    * `group` - whether this account represents a group actor
    * `discoverable` - whether the account has opted into discovery features
    * `noindex` - whether the local user has opted out of search engine indexing
    * `suspended` - whether the account has been suspended (returns with
      limited profile data when true)
    * `limited` - whether the account has been silenced
    * `last_status_at` - date (not time) of the account's last status, if any
    * `hide_collections` - whether the user hides their followers/following collections
    * `uri` - the ActivityPub actor URI of the account
    * `roles` - list of `Hunter.Role` with a visible badge
    * `attribution_domains` - domains allowed to credit the account in link previews
    * `source` - profile source data as entered by the user (plain-text `note`,
      default `privacy`, etc.), only returned by `verify_credentials` and
      `update_credentials`

  """
  alias Hunter.Api.HTTPClient

  @type t :: %__MODULE__{
          id: String.t(),
          username: String.t(),
          acct: String.t(),
          display_name: String.t(),
          note: String.t(),
          url: String.t(),
          uri: String.t(),
          avatar: String.t(),
          avatar_static: String.t(),
          header: String.t(),
          header_static: String.t(),
          locked: String.t(),
          created_at: String.t(),
          last_status_at: String.t() | nil,
          followers_count: non_neg_integer,
          following_count: non_neg_integer,
          statuses_count: non_neg_integer,
          emojis: [Hunter.Emoji.t()],
          moved: t(),
          fields: [Hunter.Field.t()],
          bot: boolean,
          group: boolean,
          discoverable: boolean | nil,
          noindex: boolean | nil,
          suspended: boolean | nil,
          limited: boolean | nil,
          hide_collections: boolean | nil,
          roles: [Hunter.Role.t()],
          attribution_domains: [String.t()],
          source: map | nil
        }

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :username,
    :acct,
    :display_name,
    :note,
    :url,
    :uri,
    :avatar,
    :avatar_static,
    :header,
    :header_static,
    :locked,
    :created_at,
    :last_status_at,
    :followers_count,
    :following_count,
    :statuses_count,
    :emojis,
    :moved,
    :fields,
    :bot,
    :group,
    :discoverable,
    :noindex,
    :suspended,
    :limited,
    :hide_collections,
    :roles,
    :attribution_domains,
    :source
  ]

  @doc """
  Retrieve account of authenticated user

  ## Parameters

    * `conn` - connection credentials

  ## Examples

        iex> conn = Hunter.new([base_url: "https://social.lou.lt", access_token: "123456"])
        %Hunter.Client{base_url: "https://social.lou.lt", access_token: "123456"}
        iex> Hunter.Account.verify_credentials(conn)
        %Hunter.Account{acct: "milmazz",
                avatar: "https://social.lou.lt/avatars/original/missing.png",
                avatar_static: "https://social.lou.lt/avatars/original/missing.png",
                created_at: "2017-04-06T17:43:55.325Z",
                display_name: "Milton Mazzarri", followers_count: 4,
                following_count: 4,
                header: "https://social.lou.lt/headers/original/missing.png",
                header_static: "https://social.lou.lt/headers/original/missing.png",
                id: "8039", locked: false, note: "", statuses_count: 3,
                url: "https://social.lou.lt/@milmazz", username: "milmazz"}

  """
  @spec verify_credentials(Hunter.Client.t()) :: Hunter.Account.t()
  def verify_credentials(conn) do
    HTTPClient.verify_credentials(conn)
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
  @spec update_credentials(Hunter.Client.t(), map) :: Hunter.Account.t()
  def update_credentials(conn, data) do
    HTTPClient.update_credentials(conn, data)
  end

  @doc """
  Retrieve account

  ## Parameters

    * `conn` - connection credentials
    * `id` - account id

  """
  @spec account(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Account.t()
  def account(conn, id) do
    HTTPClient.account(conn, id)
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

  **Note:** `max_id` and `since_id` for next and previous pages are provided in
  the `Link` header. It is **not** possible to use the `id` of the returned
  objects to construct your own URLs, because the results are sorted by an
  internal key.

  """
  @spec followers(Hunter.Client.t(), String.t() | non_neg_integer, Keyword.t()) :: [
          Hunter.Account.t()
        ]
  def followers(conn, id, options \\ []) do
    HTTPClient.followers(conn, id, options)
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

  **Note:** `max_id` and `since_id` for next and previous pages are provided in
  the `Link` header. It is **not** possible to use the `id` of the returned
  objects to construct your own URLs, because the results are sorted by an
  internal key.

  """
  @spec following(Hunter.Client.t(), String.t() | non_neg_integer, Keyword.t()) :: [
          Hunter.Account.t()
        ]
  def following(conn, id, options \\ []) do
    HTTPClient.following(conn, id, options)
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
  @spec search_account(Hunter.Client.t(), Keyword.t()) :: [Hunter.Account.t()]
  def search_account(conn, options) do
    opts = %{
      q: Keyword.fetch!(options, :q),
      limit: Keyword.get(options, :limit, 40)
    }

    HTTPClient.search_account(conn, opts)
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
  @spec blocks(Hunter.Client.t(), Keyword.t()) :: [Hunter.Account.t()]
  def blocks(conn, options \\ []) do
    HTTPClient.blocks(conn, options)
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
  @spec follow_requests(Hunter.Client.t(), Keyword.t()) :: [Hunter.Account.t()]
  def follow_requests(conn, options \\ []) do
    HTTPClient.follow_requests(conn, options)
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
  @spec mutes(Hunter.Client.t(), Keyword.t()) :: [Hunter.Account.t()]
  def mutes(conn, options \\ []) do
    HTTPClient.mutes(conn, options)
  end

  @doc """
  Accepts a follow request

  ## Parameters

    * `conn` - connection credentials
    * `id` - follow request id

  """
  @spec accept_follow_request(Hunter.Client.t(), String.t() | non_neg_integer) ::
          Hunter.Relationship.t()
  def accept_follow_request(conn, id) do
    HTTPClient.follow_request_action(conn, id, :authorize)
  end

  @doc """
  Rejects a follow request

  ## Parameters

    * `conn` - connection credentials
    * `id` - follow request id

  """
  @spec reject_follow_request(Hunter.Client.t(), String.t() | non_neg_integer) ::
          Hunter.Relationship.t()
  def reject_follow_request(conn, id) do
    HTTPClient.follow_request_action(conn, id, :reject)
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
  @spec reblogged_by(Hunter.Client.t(), String.t() | non_neg_integer, Keyword.t()) :: [
          Hunter.Account.t()
        ]
  def reblogged_by(conn, id, options \\ []) do
    HTTPClient.reblogged_by(conn, id, options)
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

  @spec favourited_by(Hunter.Client.t(), String.t() | non_neg_integer, Keyword.t()) :: [
          Hunter.Account.t()
        ]
  def favourited_by(conn, id, options \\ []) do
    HTTPClient.favourited_by(conn, id, options)
  end
end
