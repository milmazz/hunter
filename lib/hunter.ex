defmodule Hunter do
  @moduledoc """
  An Elixir client for the Mastodon API
  """

  @hunter_version Mix.Project.config()[:version]

  alias Hunter.{Api.Request, Config}

  @doc """
  Retrieve account of authenticated user

  ## Parameters

    * `conn` - connection credentials

  ## Examples

        iex> conn = Hunter.new([base_url: "https://social.lou.lt", access_token: "123456"])
        %Hunter.Client{base_url: "https://social.lou.lt", access_token: "123456"}
        iex> Hunter.verify_credentials(conn)
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
    Request.request!(conn, :get, "/api/v1/accounts/verify_credentials", :account)
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
    Request.request!(conn, :patch, "/api/v1/accounts/update_credentials", :account, data)
  end

  @doc """
  Retrieve account

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier

  """
  @spec account(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Account.t()
  def account(conn, id) do
    Request.request!(conn, :get, "/api/v1/accounts/#{id}", :account)
  end

  @doc """
  Get a list of followers

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier
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
    Request.request!(conn, :get, "/api/v1/accounts/#{id}/followers", :accounts, options)
  end

  @doc """
  Get a list of followed accounts

  ## Parameters

    * `conn` - connection credentials
    * `id` - account identifier
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
    Request.request!(conn, :get, "/api/v1/accounts/#{id}/following", :accounts, options)
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

    Request.request!(conn, :get, "/api/v1/accounts/search", :accounts, opts)
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
    Request.request!(conn, :get, "/api/v1/blocks", :accounts, options)
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
    Request.request!(conn, :get, "/api/v1/follow_requests", :accounts, options)
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
    Request.request!(conn, :get, "/api/v1/mutes", :accounts, options)
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
    Request.request!(conn, :post, "/api/v1/follow_requests/#{id}/authorize", :relationship)
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
    Request.request!(conn, :post, "/api/v1/follow_requests/#{id}/reject", :relationship)
  end

  ## Application

  @doc """
  Register a new OAuth client app on the target instance

  ## Parameters

    * `name` - name of your application
    * `redirect_uri` - where the user should be redirected after authorization,
      default: `urn:ietf:wg:oauth:2.0:oob` (no redirect)
    * `scopes` - scope list, see the scope section for more details, default: `read`
    * `website` - URL to the homepage of your app, default: `nil`
    * `options` - option list

  ## Scopes

    * `read` - read data
    * `write` - post statuses and upload media for statuses
    * `follow` - follow, unfollow, block, unblock

  Multiple scopes can be requested during the authorization phase with the `scope` query param

  ## Options

    * `save?` - persists your application information to a file, so, you can use
      them later. default: `false`
    * `api_base_url` - specifies if you want to register an application on a
      different instance. default: `https://mastodon.social`

  ## Examples

      iex> Hunter.create_app("hunter", "urn:ietf:wg:oauth:2.0:oob", ["read", "write", "follow"], nil, [save?: true, api_base_url: "https://example.com"])
      %Hunter.Application{client_id: "1234567890",
       client_secret: "1234567890",
       id: "1234"}

  """
  @spec create_app(String.t(), String.t(), [String.t()], nil | String.t(), Keyword.t()) ::
          Hunter.Application.t() | no_return
  def create_app(
        client_name,
        redirect_uris \\ "urn:ietf:wg:oauth:2.0:oob",
        scopes \\ ["read"],
        website \\ nil,
        options \\ []
      ) do
    {save?, options} = Keyword.pop(options, :save?, false)
    base_url = Keyword.get(options, :api_base_url, Config.api_base_url())

    payload = %{
      client_name: client_name,
      redirect_uris: redirect_uris,
      scopes: Enum.join(scopes, " "),
      website: website
    }

    %Hunter.Application{} =
      app = Request.request!(base_url, :post, "/api/v1/apps", :application, payload)

    app = %Hunter.Application{app | scopes: scopes, redirect_uri: redirect_uris}

    if save?, do: save_credentials(client_name, app)

    app
  end

  @doc """
  Load persisted application's credentials

  ## Parameters

    * `name` - application's name

  """
  @spec load_credentials(String.t()) :: Hunter.Application.t()
  def load_credentials(name) do
    Config.home()
    |> Path.join("apps/#{name}.json")
    |> File.read!()
    |> Poison.decode!(as: %Hunter.Application{})
  end

  defp save_credentials(name, app) do
    home = Path.join(Config.home(), "apps")

    unless File.exists?(home), do: File.mkdir_p!(home)

    File.write!("#{home}/#{name}.json", Poison.encode!(app))
  end

  @doc """
  Initializes a client

  ## Options

    * `base_url` - URL of the instance you want to connect to
    * `access_token` - [String] OAuth access token for your authenticated user

  """
  @spec new(Keyword.t()) :: Hunter.Client.t()
  def new(options \\ []), do: struct(Hunter.Client, options)

  @doc """
  User agent of the client
  """
  @spec user_agent() :: String.t()
  def user_agent, do: "Hunter.Elixir/#{version()}"

  @doc """
  Upload a media file

  ## Parameters

    * `conn` - connection credentials
    * `file` - media to be uploaded
    * `options` - option list

  ## Options

    * `description` - plain-text description of the media for accessibility (max 420 chars)
    * `focus` - two floating points, comma-delimited

  **Note:** the v2 media endpoint processes large files asynchronously: the
  returned attachment's `url` may be `nil` until the server finishes
  processing (HTTP 202). The `id` can be attached to a status with
  `create_status` as soon as processing completes.

  """
  @spec upload_media(Hunter.Client.t(), Path.t(), Keyword.t()) :: Hunter.Attachment.t()
  def upload_media(conn, file, options \\ []) do
    # stream raw byte chunks (Elixir 1.16+ argument order): the default line
    # mode rewrites \r\n and transmits fewer bytes than the declared
    # content-length
    parts =
      [file: {File.stream!(file, 65_536), filename: Path.basename(file)}] ++
        Enum.map(options, fn {key, value} -> {key, to_string(value)} end)

    Request.request!(conn, :post, "/api/v2/media", :attachment, {:form_multipart, parts})
  end

  @doc """
  Retrieve a media attachment, to check the processing status of an
  asynchronous upload

  ## Parameters

    * `conn` - connection credentials
    * `id` - attachment identifier

  """
  @spec media_attachment(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Attachment.t()
  def media_attachment(conn, id) do
    Request.request!(conn, :get, "/api/v1/media/#{id}", :attachment)
  end

  @doc """
  Update a media attachment, before it is attached to a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - attachment identifier
    * `options` - option list

  ## Options

    * `description` - plain-text description of the media for accessibility
    * `focus` - two floating points between -1.0 and 1.0, comma-delimited
    * `thumbnail` - path of a custom thumbnail image

  """
  @spec update_media(Hunter.Client.t(), String.t() | non_neg_integer, Keyword.t()) ::
          Hunter.Attachment.t()
  def update_media(conn, id, options \\ []) do
    Request.request!(conn, :put, "/api/v1/media/#{id}", :attachment, Map.new(options))
  end

  @doc """
  Delete a media attachment that is not currently attached to a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - attachment identifier

  """
  @spec delete_media(Hunter.Client.t(), String.t() | non_neg_integer) :: boolean
  def delete_media(conn, id) do
    Request.request!(conn, :delete, "/api/v1/media/#{id}", :empty)
  end

  @doc """
  Get the relationships of authenticated user towards given other users

  ## Parameters

    * `conn` - connection credentials
    * `id` - list of relationship IDs

  """
  @spec relationships(Hunter.Client.t(), [String.t() | non_neg_integer]) :: [
          Hunter.Relationship.t()
        ]
  def relationships(conn, ids) do
    Request.request!(conn, :get, "/api/v1/accounts/relationships", :relationships, %{id: ids})
  end

  @doc """
  Follow a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec follow(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Relationship.t()
  def follow(conn, id) do
    Request.request!(conn, :post, "/api/v1/accounts/#{id}/follow", :relationship)
  end

  @doc """
  Unfollow a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec unfollow(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Relationship.t()
  def unfollow(conn, id) do
    Request.request!(conn, :post, "/api/v1/accounts/#{id}/unfollow", :relationship)
  end

  @doc """
  Block a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec block(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Relationship.t()
  def block(conn, id) do
    Request.request!(conn, :post, "/api/v1/accounts/#{id}/block", :relationship)
  end

  @doc """
  Unblock a user

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec unblock(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Relationship.t()
  def unblock(conn, id) do
    Request.request!(conn, :post, "/api/v1/accounts/#{id}/unblock", :relationship)
  end

  @doc """
  Mute a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec mute(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Relationship.t()
  def mute(conn, id) do
    Request.request!(conn, :post, "/api/v1/accounts/#{id}/mute", :relationship)
  end

  @doc """
  Unmute a user

  ## Parameters

    * `conn` - connection credentials
    * `id` - user identifier

  """
  @spec unmute(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Relationship.t()
  def unmute(conn, id) do
    Request.request!(conn, :post, "/api/v1/accounts/#{id}/unmute", :relationship)
  end

  @doc """
  Search for content

  ## Parameters

    * `conn` - connection credentials
    * `q` - the search query
    * `options` - option list

  ## Options

    * `resolve` - whether to resolve non-local accounts

  """
  @spec search(Hunter.Client.t(), String.t(), Keyword.t()) :: Hunter.Result.t()
  def search(conn, query, options \\ []) do
    options = options |> Keyword.merge(q: query) |> Map.new()

    Request.request!(conn, :get, "/api/v2/search", :result, options)
  end

  @doc """
  Create new status

  ## Parameters

    * `conn` - connection credentials
    * `status` - text of the status
    * `options` - option list

  ## Options

    * `in_reply_to_id` - local ID of the status you want to reply to
    * `media_ids` - list of media IDs to attach to the status (maximum: 4)
    * `sensitive` - whether the media of the status is NSFW
    * `spoiler_text` - text to be shown as a warning before the actual content
    * `visibility` - either `direct`, `private`, `unlisted` or `public`
    * `language` - ISO 639-1 language code for the status
    * `poll` - map with `options` (list of choices) and `expires_in`
      (seconds); optional: `multiple`, `hide_totals`
    * `quoted_status_id` - ID of a status to quote
    * `scheduled_at` - ISO 8601 datetime (at least 5 minutes ahead) at which
      the status should be published; the call returns a
      `Hunter.ScheduledStatus` instead of a `Hunter.Status`
    * `idempotency_key` - unique string sent as the `Idempotency-Key` header
      to prevent duplicate submissions

  """
  @spec create_status(Hunter.Client.t(), String.t(), Keyword.t()) ::
          Hunter.Status.t() | Hunter.ScheduledStatus.t() | no_return
  def create_status(conn, status, options \\ []) do
    {idempotency_key, options} = Keyword.pop(options, :idempotency_key)
    body = options |> Keyword.put(:status, status) |> Map.new()

    headers =
      case idempotency_key do
        nil -> []
        key -> [{"idempotency-key", key}]
      end

    # scheduling a status returns a ScheduledStatus instead of a Status
    to = if Keyword.has_key?(options, :scheduled_at), do: :scheduled_status, else: :status

    Request.request!(conn, :post, "/api/v1/statuses", to, body, headers: headers)
  end

  @doc """
  Retrieve a poll

  ## Parameters

    * `conn` - connection credentials
    * `id` - poll identifier

  """
  @spec poll(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Poll.t()
  def poll(conn, id) do
    Request.request!(conn, :get, "/api/v1/polls/#{id}", :poll)
  end

  @doc """
  Vote on one or more options in a poll

  ## Parameters

    * `conn` - connection credentials
    * `id` - poll identifier
    * `choices` - list of option indices to vote for (zero-based)

  """
  @spec vote(Hunter.Client.t(), String.t() | non_neg_integer, [non_neg_integer]) ::
          Hunter.Poll.t()
  def vote(conn, id, choices) do
    Request.request!(conn, :post, "/api/v1/polls/#{id}/votes", :poll, %{choices: choices})
  end

  @doc """
  Retrieve status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec status(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Status.t()
  def status(conn, id) do
    Request.request!(conn, :get, "/api/v1/statuses/#{id}", :status)
  end

  @doc """
  Retrieve multiple statuses by id

  ## Parameters

    * `conn` - connection credentials
    * `ids` - list of status identifiers

  """
  @spec statuses_by_ids(Hunter.Client.t(), [String.t() | non_neg_integer]) :: [Hunter.Status.t()]
  def statuses_by_ids(conn, ids) do
    Request.request!(conn, :get, "/api/v1/statuses", :statuses, %{id: ids})
  end

  @doc """
  Edit a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier
    * `status` - the new text of the status
    * `options` - option list

  ## Options

    * `spoiler_text` - text to be shown as a warning before the actual content
    * `sensitive` - whether the media of the status is NSFW
    * `language` - ISO 639-1 language code for the status
    * `media_ids` - list of media IDs to attach to the status
    * `poll` - map with `options` (list of choices) and `expires_in`
      (seconds); replaces the current poll

  """
  @spec edit_status(Hunter.Client.t(), String.t() | non_neg_integer, String.t(), Keyword.t()) ::
          Hunter.Status.t() | no_return
  def edit_status(conn, id, status, options \\ []) do
    body = options |> Keyword.put(:status, status) |> Map.new()

    Request.request!(conn, :put, "/api/v1/statuses/#{id}", :status, body)
  end

  @doc """
  Retrieve the edit history of a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec status_history(Hunter.Client.t(), String.t() | non_neg_integer) :: [Hunter.StatusEdit.t()]
  def status_history(conn, id) do
    Request.request!(conn, :get, "/api/v1/statuses/#{id}/history", :status_edits)
  end

  @doc """
  Retrieve the plain-text source of a status, for editing

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec status_source(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.StatusSource.t()
  def status_source(conn, id) do
    Request.request!(conn, :get, "/api/v1/statuses/#{id}/source", :status_source)
  end

  @doc """
  Bookmark a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec bookmark(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Status.t()
  def bookmark(conn, id), do: status_action(conn, id, :bookmark)

  @doc """
  Remove a status from bookmarks

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec unbookmark(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Status.t()
  def unbookmark(conn, id), do: status_action(conn, id, :unbookmark)

  @doc """
  Fetch the user's bookmarked statuses

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of bookmarks with id less than or equal this value
    * `since_id` - get a list of bookmarks with id greater than this value
    * `min_id` - get a list of bookmarks with id greater than this value,
      immediately newer
    * `limit` - maximum number of bookmarks to get, default: 20, max: 40

  """
  @spec bookmarks(Hunter.Client.t(), Keyword.t()) :: [Hunter.Status.t()]
  def bookmarks(conn, options \\ []) do
    Request.request!(conn, :get, "/api/v1/bookmarks", :statuses, options)
  end

  @doc """
  Pin a status to the top of the user's profile

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec pin(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Status.t()
  def pin(conn, id), do: status_action(conn, id, :pin)

  @doc """
  Unpin a status from the user's profile

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec unpin(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Status.t()
  def unpin(conn, id), do: status_action(conn, id, :unpin)

  @doc """
  Mute a conversation, so its thread stops generating notifications

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec mute_conversation(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Status.t()
  def mute_conversation(conn, id), do: status_action(conn, id, :mute)

  @doc """
  Unmute a conversation

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec unmute_conversation(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Status.t()
  def unmute_conversation(conn, id), do: status_action(conn, id, :unmute)

  defp status_action(conn, id, action) do
    Request.request!(conn, :post, "/api/v1/statuses/#{id}/#{action}", :status)
  end

  @doc """
  Translate a status into some language

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier
    * `options` - option list

  ## Options

    * `lang` - ISO 639-1 language code the status should be translated into;
      defaults to the user's current locale

  """
  @spec translate_status(Hunter.Client.t(), String.t() | non_neg_integer, Keyword.t()) ::
          Hunter.Translation.t()
  def translate_status(conn, id, options \\ []) do
    Request.request!(
      conn,
      :post,
      "/api/v1/statuses/#{id}/translate",
      :translation,
      Map.new(options)
    )
  end

  @doc """
  Destroy status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec destroy_status(Hunter.Client.t(), String.t() | non_neg_integer) :: boolean
  def destroy_status(conn, id) do
    Request.request!(conn, :delete, "/api/v1/statuses/#{id}", :empty)
  end

  @doc """
  Reblog a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec reblog(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Status.t()
  def reblog(conn, id) do
    Request.request!(conn, :post, "/api/v1/statuses/#{id}/reblog", :status)
  end

  @doc """
  Undo a reblog of a status

  ## Parameters

  * `conn` - connection credentials
  * `id` - status identifier

  """
  @spec unreblog(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Status.t()
  def unreblog(conn, id) do
    Request.request!(conn, :post, "/api/v1/statuses/#{id}/unreblog", :status)
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
    Request.request!(conn, :get, "/api/v1/statuses/#{id}/reblogged_by", :accounts, options)
  end

  @doc """
  Favorite a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec favourite(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Status.t()
  def favourite(conn, id) do
    Request.request!(conn, :post, "/api/v1/statuses/#{id}/favourite", :status)
  end

  @doc """
  Undo a favorite of a status

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec unfavourite(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Status.t()
  def unfavourite(conn, id) do
    Request.request!(conn, :post, "/api/v1/statuses/#{id}/unfavourite", :status)
  end

  @doc """
  Fetch a user's favourites

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of favourites with id less than or equal this value
    * `since_id` - get a list of favourites with id greater than this value
    * `limit` - maximum of favourites to get, default: 20, max: 40

  """
  @spec favourites(Hunter.Client.t(), Keyword.t()) :: [Hunter.Status.t()]
  def favourites(conn, options \\ []) do
    Request.request!(conn, :get, "/api/v1/favourites", :statuses, options)
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
    Request.request!(conn, :get, "/api/v1/statuses/#{id}/favourited_by", :accounts, options)
  end

  @doc """
  Get a list of statuses by a user

  ## Parameters

    * `conn` - connection credentials -
    * `account_id` - account identifier
    * `options` - option list

  ## Options

    * `only_media` - only return `Hunter.Status.t` that have media attachments
    * `exclude_replies` - skip statuses that reply to other statuses
    * `max_id` - get a list of statuses with id less than or equal this value
    * `since_id` - get a list of statuses with id greater than this value
    * `limit` - maximum number of statuses to get, default: 20, max: 40

  """
  @spec statuses(Hunter.Client.t(), String.t() | non_neg_integer, Keyword.t()) :: [
          Hunter.Status.t()
        ]
  def statuses(conn, account_id, options \\ []) do
    Request.request!(conn, :get, "/api/v1/accounts/#{account_id}/statuses", :statuses, options)
  end

  @doc """
  Retrieve statuses from the home timeline

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of timelines with id less than or equal this value
    * `since_id` - get a list of timelines with id greater than this value
    * `limit` - maximum number of statuses on the requested timeline to get, default: 20, max: 40

  """
  @spec home_timeline(Hunter.Client.t(), Keyword.t()) :: [Hunter.Status.t()]
  def home_timeline(conn, options \\ []) do
    retrieve_timeline(conn, "/api/v1/timelines/home", options)
  end

  @doc """
  Retrieve statuses from the public timeline

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `local` - only return statuses originating from this instance
    * `max_id` - get a list of timelines with id less than or equal this value
    * `since_id` - get a list of timelines with id greater than this value
    * `limit` - maximum number of statuses on the requested timeline to get, default: 20, max: 40

  """
  @spec public_timeline(Hunter.Client.t(), Keyword.t()) :: [Hunter.Status.t()]
  def public_timeline(conn, options \\ []) do
    retrieve_timeline(conn, "/api/v1/timelines/public", options)
  end

  @doc """
  Retrieve statuses from a hashtag

  ## Parameters

    * `conn` - connection credentials
    * `hashtag` - string list
    * `options` - option list

  ## Options

    * `local` - only return statuses originating from this instance
    * `max_id` - get a list of timelines with id less than or equal this value
    * `since_id` - get a list of timelines with id greater than this value
    * `limit` - maximum number of statuses on the requested timeline to get, default: 20, max: 40

  """
  @spec hashtag_timeline(Hunter.Client.t(), [String.t()], Keyword.t()) :: [Hunter.Status.t()]
  def hashtag_timeline(conn, hashtag, options \\ []) do
    retrieve_timeline(conn, "/api/v1/timelines/tag/#{hashtag}", options)
  end

  @doc """
  Retrieve statuses from the given list's timeline

  ## Parameters

    * `conn` - connection credentials
    * `list_id` - list identifier
    * `options` - option list

  ## Options

    * `max_id` - get a list of timelines with id less than or equal this value
    * `since_id` - get a list of timelines with id greater than this value
    * `limit` - maximum number of statuses on the requested timeline to get, default: 20, max: 40

  """
  @spec list_timeline(Hunter.Client.t(), String.t() | non_neg_integer, Keyword.t()) :: [
          Hunter.Status.t()
        ]
  def list_timeline(conn, list_id, options \\ []) do
    retrieve_timeline(conn, "/api/v1/timelines/list/#{list_id}", options)
  end

  defp retrieve_timeline(conn, endpoint, options) do
    Request.request!(conn, :get, endpoint, :statuses, options)
  end

  @doc """
  Retrieve all lists the user owns

  ## Parameters

    * `conn` - connection credentials

  """
  @spec lists(Hunter.Client.t()) :: [Hunter.List.t()]
  def lists(conn) do
    Request.request!(conn, :get, "/api/v1/lists", :lists)
  end

  @doc """
  Retrieve a list

  ## Parameters

    * `conn` - connection credentials
    * `id` - list identifier

  """
  @spec list(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.List.t()
  def list(conn, id) do
    Request.request!(conn, :get, "/api/v1/lists/#{id}", :list)
  end

  @doc """
  Create a new list

  ## Parameters

    * `conn` - connection credentials
    * `title` - the title of the list
    * `options` - option list

  ## Options

    * `replies_policy` - which replies should be shown in the list, one of:
      `followed`, `list`, `none`; default: `list`
    * `exclusive` - whether members of the list are removed from the home
      timeline

  """
  @spec create_list(Hunter.Client.t(), String.t(), Keyword.t()) :: Hunter.List.t()
  def create_list(conn, title, options \\ []) do
    body = options |> Keyword.put(:title, title) |> Map.new()

    Request.request!(conn, :post, "/api/v1/lists", :list, body)
  end

  @doc """
  Update a list

  ## Parameters

    * `conn` - connection credentials
    * `id` - list identifier
    * `options` - option list

  ## Options

    * `title` - the new title of the list
    * `replies_policy` - which replies should be shown in the list, one of:
      `followed`, `list`, `none`
    * `exclusive` - whether members of the list are removed from the home
      timeline

  """
  @spec update_list(Hunter.Client.t(), String.t() | non_neg_integer, Keyword.t()) ::
          Hunter.List.t()
  def update_list(conn, id, options) do
    Request.request!(conn, :put, "/api/v1/lists/#{id}", :list, Map.new(options))
  end

  @doc """
  Delete a list

  ## Parameters

    * `conn` - connection credentials
    * `id` - list identifier

  """
  @spec destroy_list(Hunter.Client.t(), String.t() | non_neg_integer) :: boolean
  def destroy_list(conn, id) do
    Request.request!(conn, :delete, "/api/v1/lists/#{id}", :empty)
  end

  @doc """
  Retrieve the accounts in a list

  ## Parameters

    * `conn` - connection credentials
    * `id` - list identifier
    * `options` - option list

  ## Options

    * `max_id` - get a list of accounts with id less than or equal this value
    * `since_id` - get a list of accounts with id greater than this value
    * `limit` - maximum number of accounts to get, default: 40; set to 0 to
      get all accounts in the list

  """
  @spec list_accounts(Hunter.Client.t(), String.t() | non_neg_integer, Keyword.t()) :: [
          Hunter.Account.t()
        ]
  def list_accounts(conn, id, options \\ []) do
    Request.request!(conn, :get, "/api/v1/lists/#{id}/accounts", :accounts, options)
  end

  @doc """
  Add accounts to a list; the user must be following each of them

  ## Parameters

    * `conn` - connection credentials
    * `id` - list identifier
    * `account_ids` - account identifiers to add

  """
  @spec add_accounts_to_list(Hunter.Client.t(), String.t() | non_neg_integer, [
          String.t() | non_neg_integer
        ]) :: boolean
  def add_accounts_to_list(conn, id, account_ids) do
    Request.request!(conn, :post, "/api/v1/lists/#{id}/accounts", :empty, %{
      account_ids: account_ids
    })
  end

  @doc """
  Remove accounts from a list

  ## Parameters

    * `conn` - connection credentials
    * `id` - list identifier
    * `account_ids` - account identifiers to remove

  """
  @spec remove_accounts_from_list(Hunter.Client.t(), String.t() | non_neg_integer, [
          String.t() | non_neg_integer
        ]) ::
          boolean
  def remove_accounts_from_list(conn, id, account_ids) do
    Request.request!(conn, :delete, "/api/v1/lists/#{id}/accounts", :empty, %{
      account_ids: account_ids
    })
  end

  @doc """
  Retrieve the user's lists that contain a given account

  ## Parameters

    * `conn` - connection credentials
    * `account_id` - account identifier

  """
  @spec account_lists(Hunter.Client.t(), String.t() | non_neg_integer) :: [Hunter.List.t()]
  def account_lists(conn, account_id) do
    Request.request!(conn, :get, "/api/v1/accounts/#{account_id}/lists", :lists)
  end

  @doc """
  Retrieve instance information

  ## Parameters

    * `conn` - connection credentials

  """
  @spec instance_info(Hunter.Client.t()) :: Hunter.Instance.t()
  defdelegate instance_info(conn), to: Hunter.Instance

  @doc """
  Retrieve user's notifications

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of notifications with id less than or equal this value
    * `since_id` - get a list of notifications with id greater than this value
    * `limit` - maximum number of notifications to get, default: 15, max: 30

  ## Examples

      Hunter.notifications(conn)
      #=> [%Hunter.Notification{account: %{"acct" => "paperswelove@mstdn.io", ...}]

  """
  @spec notifications(Hunter.Client.t(), Keyword.t()) :: [Hunter.Notification.t()]
  def notifications(conn, options \\ []) do
    Request.request!(conn, :get, "/api/v1/notifications", :notifications, options)
  end

  @doc """
  Retrieve single notification

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification identifier

  ## Examples

      Hunter.notification(conn, 17_476)
      #=> %Hunter.Notification{account: %{"acct" => "paperswelove@mstdn.io", ...}

  """
  @spec notification(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Notification.t()
  def notification(conn, id) do
    Request.request!(conn, :get, "/api/v1/notifications/#{id}", :notification)
  end

  @doc """
  Deletes all notifications from the Mastodon server for the authenticated user

  ## Parameters

    * `conn` - connection credentials

  """
  @spec clear_notifications(Hunter.Client.t()) :: boolean
  def clear_notifications(conn) do
    Request.request!(conn, :post, "/api/v1/notifications/clear", :empty)
  end

  @doc """
  Dismiss a single notification

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification id

  """
  @spec clear_notification(Hunter.Client.t(), String.t() | non_neg_integer) :: boolean
  def clear_notification(conn, id) do
    Request.request!(conn, :post, "/api/v1/notifications/#{id}/dismiss", :empty)
  end

  @doc """
  Retrieve the number of unread notifications, capped by the server

  ## Parameters

    * `conn` - connection credentials

  """
  @spec unread_count(Hunter.Client.t()) :: non_neg_integer
  def unread_count(conn) do
    Request.request!(conn, :get, "/api/v1/notifications/unread_count", nil)
    |> Map.fetch!("count")
  end

  @doc """
  Retrieve the notification filtering policy for the user

  ## Parameters

    * `conn` - connection credentials

  """
  @spec notification_policy(Hunter.Client.t()) :: Hunter.NotificationPolicy.t()
  def notification_policy(conn) do
    Request.request!(conn, :get, "/api/v2/notifications/policy", :notification_policy)
  end

  @doc """
  Update the notification filtering policy for the user

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

  Each takes one of `accept`, `filter` or `drop`:

    * `for_not_following`
    * `for_not_followers`
    * `for_new_accounts`
    * `for_private_mentions`
    * `for_limited_accounts`

  """
  @spec update_notification_policy(Hunter.Client.t(), Keyword.t()) ::
          Hunter.NotificationPolicy.t()
  def update_notification_policy(conn, options) do
    Request.request!(
      conn,
      :patch,
      "/api/v2/notifications/policy",
      :notification_policy,
      Map.new(options)
    )
  end

  @doc """
  Retrieve notification requests (groups of filtered notifications)

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get requests with id less than or equal this value
    * `since_id` - get requests with id greater than this value
    * `limit` - maximum number of requests to get, default: 40, max: 80

  """
  @spec notification_requests(Hunter.Client.t(), Keyword.t()) :: [
          Hunter.NotificationRequest.t()
        ]
  def notification_requests(conn, options \\ []) do
    Request.request!(
      conn,
      :get,
      "/api/v1/notifications/requests",
      :notification_requests,
      options
    )
  end

  @doc """
  Retrieve a single notification request

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification request identifier

  """
  @spec notification_request(Hunter.Client.t(), String.t() | non_neg_integer) ::
          Hunter.NotificationRequest.t()
  def notification_request(conn, id) do
    Request.request!(conn, :get, "/api/v1/notifications/requests/#{id}", :notification_request)
  end

  @doc """
  Accept a notification request

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification request identifier

  """
  @spec accept_notification_request(Hunter.Client.t(), String.t() | non_neg_integer) :: boolean
  def accept_notification_request(conn, id) do
    Request.request!(conn, :post, "/api/v1/notifications/requests/#{id}/accept", :empty)
  end

  @doc """
  Dismiss a notification request

  ## Parameters

    * `conn` - connection credentials
    * `id` - notification request identifier

  """
  @spec dismiss_notification_request(Hunter.Client.t(), String.t() | non_neg_integer) :: boolean
  def dismiss_notification_request(conn, id) do
    Request.request!(conn, :post, "/api/v1/notifications/requests/#{id}/dismiss", :empty)
  end

  @doc """
  Accept multiple notification requests

  ## Parameters

    * `conn` - connection credentials
    * `ids` - notification request identifiers

  """
  @spec accept_notification_requests(Hunter.Client.t(), [String.t() | non_neg_integer]) ::
          boolean
  def accept_notification_requests(conn, ids) do
    Request.request!(conn, :post, "/api/v1/notifications/requests/accept", :empty, %{id: ids})
  end

  @doc """
  Dismiss multiple notification requests

  ## Parameters

    * `conn` - connection credentials
    * `ids` - notification request identifiers

  """
  @spec dismiss_notification_requests(Hunter.Client.t(), [String.t() | non_neg_integer]) ::
          boolean
  def dismiss_notification_requests(conn, ids) do
    Request.request!(conn, :post, "/api/v1/notifications/requests/dismiss", :empty, %{id: ids})
  end

  @doc """
  Check whether accepted notification requests have been merged

  ## Parameters

    * `conn` - connection credentials

  """
  @spec notification_requests_merged?(Hunter.Client.t()) :: boolean
  def notification_requests_merged?(conn) do
    Request.request!(conn, :get, "/api/v1/notifications/requests/merged", nil)
    |> Map.fetch!("merged")
  end

  @doc """
  Retrieve grouped notifications, together with the accounts and statuses
  they reference

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get groups with id less than or equal this value
    * `since_id` - get groups with id greater than this value
    * `limit` - maximum number of groups to get, default: 40, max: 80
    * `types` - notification types to include
    * `exclude_types` - notification types to exclude
    * `grouped_types` - which types can be grouped together

  """
  @spec grouped_notifications(Hunter.Client.t(), Keyword.t()) ::
          Hunter.GroupedNotificationsResults.t()
  def grouped_notifications(conn, options \\ []) do
    Request.request!(conn, :get, "/api/v2/notifications", :grouped_notifications, options)
  end

  @doc """
  Retrieve a single notification group by its group key

  ## Parameters

    * `conn` - connection credentials
    * `group_key` - notification group key

  """
  @spec notification_group(Hunter.Client.t(), String.t()) ::
          Hunter.GroupedNotificationsResults.t()
  def notification_group(conn, group_key) do
    Request.request!(conn, :get, "/api/v2/notifications/#{group_key}", :grouped_notifications)
  end

  @doc """
  Dismiss a notification group

  ## Parameters

    * `conn` - connection credentials
    * `group_key` - notification group key

  """
  @spec dismiss_notification_group(Hunter.Client.t(), String.t()) :: boolean
  def dismiss_notification_group(conn, group_key) do
    Request.request!(conn, :post, "/api/v2/notifications/#{group_key}/dismiss", :empty)
  end

  @doc """
  Retrieve the accounts of all notifications in a notification group

  ## Parameters

    * `conn` - connection credentials
    * `group_key` - notification group key

  """
  @spec notification_group_accounts(Hunter.Client.t(), String.t()) :: [Hunter.Account.t()]
  def notification_group_accounts(conn, group_key) do
    Request.request!(conn, :get, "/api/v2/notifications/#{group_key}/accounts", :accounts)
  end

  @doc """
  Retrieve the number of unread notification groups, capped by the server

  ## Parameters

    * `conn` - connection credentials

  """
  @spec grouped_unread_count(Hunter.Client.t()) :: non_neg_integer
  def grouped_unread_count(conn) do
    Request.request!(conn, :get, "/api/v2/notifications/unread_count", nil)
    |> Map.fetch!("count")
  end

  @doc """
  Subscribe to Web Push notifications; each access token can have exactly
  one subscription, and creating a new one replaces it

  ## Parameters

    * `conn` - connection credentials
    * `subscription` - map with `endpoint`, `keys` (`p256dh` and `auth`)
      and optionally `standard`
    * `data` - optional map with `alerts` and `policy`

  """
  @spec create_push_subscription(Hunter.Client.t(), map, map) ::
          Hunter.WebPushSubscription.t()
  def create_push_subscription(conn, subscription, data \\ %{}) do
    Request.request!(conn, :post, "/api/v1/push/subscription", :web_push_subscription, %{
      subscription: subscription,
      data: data
    })
  end

  @doc """
  Retrieve the Web Push subscription tied to the access token

  ## Parameters

    * `conn` - connection credentials

  """
  @spec push_subscription(Hunter.Client.t()) :: Hunter.WebPushSubscription.t()
  def push_subscription(conn) do
    Request.request!(conn, :get, "/api/v1/push/subscription", :web_push_subscription)
  end

  @doc """
  Update the `data` portion of the Web Push subscription

  ## Parameters

    * `conn` - connection credentials
    * `data` - map with `alerts` and/or `policy`

  """
  @spec update_push_subscription(Hunter.Client.t(), map) :: Hunter.WebPushSubscription.t()
  def update_push_subscription(conn, data) do
    Request.request!(conn, :put, "/api/v1/push/subscription", :web_push_subscription, %{
      data: data
    })
  end

  @doc """
  Remove the Web Push subscription tied to the access token

  ## Parameters

    * `conn` - connection credentials

  """
  @spec delete_push_subscription(Hunter.Client.t()) :: boolean
  def delete_push_subscription(conn) do
    Request.request!(conn, :delete, "/api/v1/push/subscription", :empty)
  end

  @doc """
  Report a user

  ## Parameters

    * `conn` - connection credentials
    * `account_id` - the ID of the account to report
    * `status_ids` - the IDs of statuses to report
    * `comment` - a comment to associate with the report

  """
  @spec report(
          Hunter.Client.t(),
          String.t() | non_neg_integer,
          [String.t() | non_neg_integer],
          String.t()
        ) ::
          Hunter.Report.t()
  defdelegate report(conn, account_id, status_ids, comment), to: Hunter.Report

  @doc """
  Retrieve status context

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec status_context(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Context.t()
  def status_context(conn, id) do
    Request.request!(conn, :get, "/api/v1/statuses/#{id}/context", :context)
  end

  @doc """
  Retrieve access token

  ## Parameters

    * `app` - application details, see: `Hunter.create_app/5` for more details.
    * `username` - account's email
    * `password` - account's password
    * `base_url` - API base url, default: `https://mastodon.social`

  """
  @spec log_in(Hunter.Application.t(), String.t(), String.t(), String.t()) :: Hunter.Client.t()
  def log_in(
        %Hunter.Application{} = app,
        username,
        password,
        base_url \\ "https://mastodon.social"
      ) do
    base_url = base_url || Config.api_base_url()

    payload = %{
      client_id: app.client_id,
      client_secret: app.client_secret,
      grant_type: "password",
      username: username,
      password: password
    }

    payload =
      case app.scopes do
        scopes when is_list(scopes) and scopes != [] ->
          Map.put(payload, :scope, Enum.join(scopes, " "))

        _ ->
          payload
      end

    response = Request.request!(base_url, :post, "/oauth/token", nil, payload)

    %Hunter.Client{base_url: base_url, access_token: response["access_token"]}
  end

  @doc """
  Retrieve access token via OAuth

  ## Parameters
    * `app` - application details, see: `Hunter.create_app/5` for more details.
    * `oauth_code` - OAuth authentication code
    * `base_url` - API base url, default: `https://mastodon.social`
  """
  @spec log_in_oauth(Hunter.Application.t(), String.t(), String.t()) :: Hunter.Client.t()
  def log_in_oauth(%Hunter.Application{} = app, oauth_code, base_url \\ "https://mastodon.social") do
    base_url = base_url || Config.api_base_url()

    payload = %{
      client_id: app.client_id,
      client_secret: app.client_secret,
      grant_type: "authorization_code",
      code: oauth_code,
      # Doorkeeper rejects the exchange without a redirect_uri matching the
      # authorization; fall back to create_app's default for stale credentials
      redirect_uri: app.redirect_uri || "urn:ietf:wg:oauth:2.0:oob"
    }

    response = Request.request!(base_url, :post, "/oauth/token", nil, payload)

    %Hunter.Client{base_url: base_url, access_token: response["access_token"]}
  end

  @doc """
  Fetch user's blocked domains

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of blocks with id less than or equal this value
    * `since_id` - get a list of blocks with id greater than this value
    * `limit` - maximum number of blocks to get, default: 40, max: 80

  """
  defdelegate blocked_domains(conn, options \\ []), to: Hunter.Domain

  @doc """
  Block a domain

  ## Parameters

    * `conn` - connection credentials
    * `domain` - domain to block

  """
  @spec block_domain(Hunter.Client.t(), String.t()) :: boolean()
  defdelegate block_domain(conn, domain), to: Hunter.Domain

  @doc """
  Unblock a domain

  ## Parameters

    * `conn` - connection credentials
    * `domain` - domain to unblock

  """
  @spec unblock_domain(Hunter.Client.t(), String.t()) :: boolean()
  defdelegate unblock_domain(conn, domain), to: Hunter.Domain

  @doc """
  Returns Hunter version
  """
  @spec version() :: String.t()
  def version, do: @hunter_version
end
