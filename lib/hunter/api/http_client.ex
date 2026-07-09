defmodule Hunter.Api.HTTPClient do
  @moduledoc """
  HTTP Client for Hunter
  """

  alias Hunter.{Api.Request, Api.Transformer, Config}

  def verify_credentials(conn) do
    "/api/v1/accounts/verify_credentials"
    |> process_url(conn)
    |> request!(:account, :get, [], conn)
  end

  def update_credentials(conn, data) do
    "/api/v1/accounts/update_credentials"
    |> process_url(conn)
    |> request!(:account, :patch, data, conn)
  end

  def account(conn, id) do
    "/api/v1/accounts/#{id}"
    |> process_url(conn)
    |> request!(:account, :get, [], conn)
  end

  def followers(conn, id, options) do
    "/api/v1/accounts/#{id}/followers"
    |> process_url(conn)
    |> request!(:accounts, :get, options, conn)
  end

  def following(conn, id, options) do
    "/api/v1/accounts/#{id}/following"
    |> process_url(conn)
    |> request!(:accounts, :get, options, conn)
  end

  def search_account(conn, options) do
    "/api/v1/accounts/search"
    |> process_url(conn)
    |> request!(:accounts, :get, options, conn)
  end

  def blocks(conn, options) do
    "/api/v1/blocks"
    |> process_url(conn)
    |> request!(:accounts, :get, options, conn)
  end

  def follow_requests(conn, options) do
    "/api/v1/follow_requests"
    |> process_url(conn)
    |> request!(:accounts, :get, options, conn)
  end

  def mutes(conn, options) do
    "/api/v1/mutes"
    |> process_url(conn)
    |> request!(:accounts, :get, options, conn)
  end

  def follow_request_action(conn, id, action) when action in [:authorize, :reject] do
    "/api/v1/follow_requests/#{id}/#{action}"
    |> process_url(conn)
    |> request!(:relationship, :post, [], conn)
  end

  def create_app(name, redirect_uri, scopes, website, base_url) do
    payload = %{
      client_name: name,
      redirect_uris: redirect_uri,
      scopes: Enum.join(scopes, " "),
      website: website
    }

    %Hunter.Application{} =
      app =
      "/api/v1/apps"
      |> process_url(base_url)
      |> request!(:application, :post, payload)

    %Hunter.Application{app | scopes: scopes, redirect_uri: redirect_uri}
  end

  def upload_media(conn, file, options) do
    # stream raw byte chunks: the default line mode rewrites \r\n and would
    # transmit fewer bytes than the declared content-length
    parts =
      [file: {File.stream!(file, [], 65_536), filename: Path.basename(file)}] ++
        Enum.map(options, fn {key, value} -> {key, to_string(value)} end)

    "/api/v2/media"
    |> process_url(conn)
    |> request!(:attachment, :post, {:form_multipart, parts}, conn)
  end

  def media_attachment(conn, id) do
    "/api/v1/media/#{id}"
    |> process_url(conn)
    |> request!(:attachment, :get, [], conn)
  end

  def update_media(conn, id, options) do
    "/api/v1/media/#{id}"
    |> process_url(conn)
    |> request!(:attachment, :put, Map.new(options), conn)
  end

  def delete_media(conn, id) do
    "/api/v1/media/#{id}"
    |> process_url(conn)
    |> request!(nil, :delete, [], conn)
  end

  def relationships(conn, ids) do
    "/api/v1/accounts/relationships"
    |> process_url(conn)
    |> request!(:relationships, :get, %{id: ids}, conn)
  end

  def follow(conn, id) do
    "/api/v1/accounts/#{id}/follow"
    |> process_url(conn)
    |> request!(:relationship, :post, [], conn)
  end

  def unfollow(conn, id) do
    "/api/v1/accounts/#{id}/unfollow"
    |> process_url(conn)
    |> request!(:relationship, :post, [], conn)
  end

  def block(conn, id) do
    "/api/v1/accounts/#{id}/block"
    |> process_url(conn)
    |> request!(:relationship, :post, [], conn)
  end

  def unblock(conn, id) do
    "/api/v1/accounts/#{id}/unblock"
    |> process_url(conn)
    |> request!(:relationship, :post, [], conn)
  end

  def mute(conn, id) do
    "/api/v1/accounts/#{id}/mute"
    |> process_url(conn)
    |> request!(:relationship, :post, [], conn)
  end

  def unmute(conn, id) do
    "/api/v1/accounts/#{id}/unmute"
    |> process_url(conn)
    |> request!(:relationship, :post, [], conn)
  end

  def search(conn, query, options) do
    options = options |> Keyword.merge(q: query) |> Map.new()

    "/api/v2/search"
    |> process_url(conn)
    |> request!(:result, :get, options, conn)
  end

  def create_status(conn, status, options) do
    {idempotency_key, options} = Keyword.pop(options, :idempotency_key)
    body = options |> Keyword.put(:status, status) |> Map.new()

    headers =
      case idempotency_key do
        nil -> get_headers(conn)
        key -> get_headers(conn) ++ [{:"Idempotency-Key", key}]
      end

    # scheduling a status returns a ScheduledStatus instead of a Status
    to = if Keyword.has_key?(options, :scheduled_at), do: :scheduled_status, else: :status

    "/api/v1/statuses"
    |> process_url(conn)
    |> request!(to, :post, body, headers)
  end

  def poll(conn, id) do
    "/api/v1/polls/#{id}"
    |> process_url(conn)
    |> request!(:poll, :get, [], conn)
  end

  def vote(conn, id, choices) do
    "/api/v1/polls/#{id}/votes"
    |> process_url(conn)
    |> request!(:poll, :post, %{choices: choices}, conn)
  end

  def status(conn, id) do
    "/api/v1/statuses/#{id}"
    |> process_url(conn)
    |> request!(:status, :get, [], conn)
  end

  def destroy_status(conn, id) do
    "/api/v1/statuses/#{id}"
    |> process_url(conn)
    |> request!(nil, :delete, [], conn)
  end

  def statuses_by_ids(conn, ids) do
    "/api/v1/statuses"
    |> process_url(conn)
    |> request!(:statuses, :get, %{id: ids}, conn)
  end

  def edit_status(conn, id, status, options) do
    body = options |> Keyword.put(:status, status) |> Map.new()

    "/api/v1/statuses/#{id}"
    |> process_url(conn)
    |> request!(:status, :put, body, conn)
  end

  def status_history(conn, id) do
    "/api/v1/statuses/#{id}/history"
    |> process_url(conn)
    |> request!(:status_edits, :get, [], conn)
  end

  def status_source(conn, id) do
    "/api/v1/statuses/#{id}/source"
    |> process_url(conn)
    |> request!(:status_source, :get, [], conn)
  end

  def bookmark(conn, id), do: status_action(conn, id, :bookmark)

  def unbookmark(conn, id), do: status_action(conn, id, :unbookmark)

  def pin(conn, id), do: status_action(conn, id, :pin)

  def unpin(conn, id), do: status_action(conn, id, :unpin)

  def mute_conversation(conn, id), do: status_action(conn, id, :mute)

  def unmute_conversation(conn, id), do: status_action(conn, id, :unmute)

  defp status_action(conn, id, action) do
    "/api/v1/statuses/#{id}/#{action}"
    |> process_url(conn)
    |> request!(:status, :post, [], conn)
  end

  def bookmarks(conn, options) do
    "/api/v1/bookmarks"
    |> process_url(conn)
    |> request!(:statuses, :get, options, conn)
  end

  def translate_status(conn, id, options) do
    "/api/v1/statuses/#{id}/translate"
    |> process_url(conn)
    |> request!(:translation, :post, Map.new(options), conn)
  end

  def reblog(conn, id) do
    "/api/v1/statuses/#{id}/reblog"
    |> process_url(conn)
    |> request!(:status, :post, [], conn)
  end

  def unreblog(conn, id) do
    "/api/v1/statuses/#{id}/unreblog"
    |> process_url(conn)
    |> request!(:status, :post, [], conn)
  end

  def reblogged_by(conn, id, options) do
    "/api/v1/statuses/#{id}/reblogged_by"
    |> process_url(conn)
    |> request!(:accounts, :get, options, conn)
  end

  def favourite(conn, id) do
    "/api/v1/statuses/#{id}/favourite"
    |> process_url(conn)
    |> request!(:status, :post, [], conn)
  end

  def unfavourite(conn, id) do
    "/api/v1/statuses/#{id}/unfavourite"
    |> process_url(conn)
    |> request!(:status, :post, [], conn)
  end

  def favourites(conn, options) do
    "/api/v1/favourites"
    |> process_url(conn)
    |> request!(:statuses, :get, options, conn)
  end

  def favourited_by(conn, id, options) do
    "/api/v1/statuses/#{id}/favourited_by"
    |> process_url(conn)
    |> request!(:accounts, :get, options, conn)
  end

  def statuses(conn, account_id, options) do
    "/api/v1/accounts/#{account_id}/statuses"
    |> process_url(conn)
    |> request!(:statuses, :get, options, conn)
  end

  def home_timeline(conn, options) do
    retrieve_timeline(conn, "/api/v1/timelines/home", options)
  end

  def public_timeline(conn, options) do
    retrieve_timeline(conn, "/api/v1/timelines/public", options)
  end

  def hashtag_timeline(conn, hashtag, options) do
    retrieve_timeline(conn, "/api/v1/timelines/tag/#{hashtag}", options)
  end

  def list_timeline(conn, list_id, options) do
    retrieve_timeline(conn, "/api/v1/timelines/list/#{list_id}", options)
  end

  def lists(conn) do
    "/api/v1/lists"
    |> process_url(conn)
    |> request!(:lists, :get, [], conn)
  end

  def list(conn, id) do
    "/api/v1/lists/#{id}"
    |> process_url(conn)
    |> request!(:list, :get, [], conn)
  end

  def create_list(conn, title, options) do
    body = options |> Keyword.put(:title, title) |> Map.new()

    "/api/v1/lists"
    |> process_url(conn)
    |> request!(:list, :post, body, conn)
  end

  def update_list(conn, id, options) do
    "/api/v1/lists/#{id}"
    |> process_url(conn)
    |> request!(:list, :put, Map.new(options), conn)
  end

  def destroy_list(conn, id) do
    "/api/v1/lists/#{id}"
    |> process_url(conn)
    |> request!(nil, :delete, [], conn)
  end

  def list_accounts(conn, id, options) do
    "/api/v1/lists/#{id}/accounts"
    |> process_url(conn)
    |> request!(:accounts, :get, options, conn)
  end

  def add_accounts_to_list(conn, id, account_ids) do
    "/api/v1/lists/#{id}/accounts"
    |> process_url(conn)
    |> request!(nil, :post, %{account_ids: account_ids}, conn)
  end

  def remove_accounts_from_list(conn, id, account_ids) do
    "/api/v1/lists/#{id}/accounts"
    |> process_url(conn)
    |> request!(nil, :delete, %{account_ids: account_ids}, conn)
  end

  def account_lists(conn, account_id) do
    "/api/v1/accounts/#{account_id}/lists"
    |> process_url(conn)
    |> request!(:lists, :get, [], conn)
  end

  defp retrieve_timeline(conn, endpoint, options) do
    endpoint
    |> process_url(conn)
    |> request!(:statuses, :get, options, conn)
  end

  def instance_info(conn) do
    "/api/v2/instance"
    |> process_url(conn)
    |> request!(:instance, :get, [], conn)
  end

  def notifications(conn, options) do
    "/api/v1/notifications"
    |> process_url(conn)
    |> request!(:notifications, :get, options, conn)
  end

  def notification(conn, id) do
    "/api/v1/notifications/#{id}"
    |> process_url(conn)
    |> request!(:notification, :get, [], conn)
  end

  def clear_notifications(conn) do
    "/api/v1/notifications/clear"
    |> process_url(conn)
    |> request!(nil, :post, [], conn)
  end

  def clear_notification(conn, id) do
    "/api/v1/notifications/#{id}/dismiss"
    |> process_url(conn)
    |> request!(nil, :post, [], conn)
  end

  def report(conn, account_id, status_ids, comment) do
    payload = %{
      account_id: account_id,
      status_ids: status_ids,
      comment: comment
    }

    "/api/v1/reports"
    |> process_url(conn)
    |> request!(:report, :post, payload, conn)
  end

  def status_context(conn, id) do
    "/api/v1/statuses/#{id}/context"
    |> process_url(conn)
    |> request!(:context, :get, [], conn)
  end

  def log_in(%Hunter.Application{} = app, username, password, base_url) do
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

    response =
      "/oauth/token"
      |> process_url(base_url)
      |> request!(nil, :post, payload)

    %Hunter.Client{base_url: base_url, access_token: response["access_token"]}
  end

  def log_in_oauth(%Hunter.Application{} = app, oauth_code, base_url) do
    payload = %{
      client_id: app.client_id,
      client_secret: app.client_secret,
      grant_type: "authorization_code",
      code: oauth_code,
      # Doorkeeper rejects the exchange without a redirect_uri matching the
      # authorization; fall back to create_app's default for stale credentials
      redirect_uri: app.redirect_uri || "urn:ietf:wg:oauth:2.0:oob"
    }

    response =
      "/oauth/token"
      |> process_url(base_url)
      |> request!(nil, :post, payload)

    %Hunter.Client{base_url: base_url, access_token: response["access_token"]}
  end

  def blocked_domains(conn, options) do
    "/api/v1/domain_blocks"
    |> process_url(conn)
    |> request!(nil, :get, options, conn)
  end

  def block_domain(conn, domain) do
    "/api/v1/domain_blocks"
    |> process_url(conn)
    |> request!(nil, :post, %{domain: domain}, conn)
  end

  def unblock_domain(conn, domain) do
    "/api/v1/domain_blocks"
    |> process_url(conn)
    |> request!(nil, :delete, %{domain: domain}, conn)
  end

  ## Helpers
  defp request!(url, to, method, payload, conn \\ nil) do
    headers = get_headers(conn)

    case Request.request(method, url, payload, headers, Config.req_options()) do
      {:ok, body} ->
        Transformer.transform(body, to)

      {:error, reason} ->
        raise Hunter.Error, reason: reason
    end
  end

  defp get_headers(nil), do: []

  defp get_headers(%Hunter.Client{access_token: token}) do
    [{"authorization", "Bearer #{token}"}]
  end

  defp get_headers(headers) when is_list(headers), do: headers

  defp process_url(endpoint, %Hunter.Client{base_url: base_url}) do
    process_url(endpoint, base_url)
  end

  defp process_url(endpoint, base_url) when is_binary(base_url) do
    base_url <> endpoint
  end
end
