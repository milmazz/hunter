defmodule Hunter.Api.HTTPClient do
  @moduledoc """
  HTTP Client for Hunter
  """

  alias Hunter.{Api.Request, Config}

  @behaviour Hunter.Api

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

  def follow_by_uri(conn, uri) do
    "/api/v1/follows"
    |> process_url(conn)
    |> request!(:account, :post, %{uri: uri}, conn)
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
    "/api/v1/follow_requests/#{action}"
    |> process_url(conn)
    |> request!(nil, :post, %{id: id}, conn)
  end

  def create_app(name, redirect_uri, scopes, website, base_url) do
    payload = %{
      client_name: name,
      redirect_uris: redirect_uri,
      scopes: Enum.join(scopes, " "),
      website: website
    }

    "/api/v1/apps"
    |> process_url(base_url)
    |> request!(:application, :post, payload)
  end

  def upload_media(conn, file, options) do
    options =
      [{:file, file, {"form-data", [name: "file", filename: Path.basename(file)]}, []}] ++
        Enum.map(options, fn {key, value} -> {to_string(key), value} end)

    headers =
      conn
      |> get_headers()
      |> Keyword.put(:"Content-Type", "multipart/form-data")

    "/api/v1/media"
    |> process_url(conn)
    |> request!(:attachment, :post, {:multipart, options}, headers)
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
    body = options |> Keyword.put(:status, status) |> Map.new()

    "/api/v1/statuses"
    |> process_url(conn)
    |> request!(:status, :post, body, conn)
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

  defp retrieve_timeline(conn, endpoint, options) do
    endpoint
    |> process_url(conn)
    |> request!(:statuses, :get, options, conn)
  end

  def instance_info(conn) do
    "/api/v1/instance"
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
    "/api/v1/notifications/dismiss/#{id}"
    |> process_url(conn)
    |> request!(nil, :post, [], conn)
  end

  def reports(conn) do
    "/api/v1/reports"
    |> process_url(conn)
    |> request!(:reports, :get, [], conn)
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

  def card_by_status(conn, id) do
    "/api/v1/statuses/#{id}/card"
    |> process_url(conn)
    |> request!(:card, :get, [], conn)
  end

  def log_in(
        %Hunter.Application{client_id: client_id, client_secret: client_secret},
        username,
        password,
        base_url
      ) do
    payload = %{
      client_id: client_id,
      client_secret: client_secret,
      grant_type: "password",
      username: username,
      password: password
    }

    response =
      "/oauth/token"
      |> process_url(base_url)
      |> request!(nil, :post, payload)

    %Hunter.Client{base_url: base_url, bearer_token: response["access_token"]}
  end

  def blocked_domains(conn, options) do
    "/api/v1/domain_blocks"
    |> process_url(conn)
    |> request!(nil, :get, options, conn)
  end

  def block_domain(conn, domain) do
    "/api/v1/domain_blocks"
    |> process_url(conn)
    |> request!(nil, :post, %{domain: domain})
  end

  def unblock_domain(conn, domain) do
    "/api/v1/domain_blocks"
    |> process_url(conn)
    |> request!(nil, :delete, %{domain: domain})
  end

  ## Helpers
  defp request!(url, to, method, payload, conn \\ nil) do
    headers = get_headers(conn)

    case Request.request(method, url, payload, headers, Config.http_options()) do
      {:ok, body} ->
        transform(body, to)

      {:error, reason} ->
        raise Hunter.Error, reason: reason
    end
  end

  defp get_headers(nil), do: []

  defp get_headers(%Hunter.Client{bearer_token: token}) do
    [{:Authorization, "Bearer #{token}"}]
  end

  defp get_headers(headers) when is_list(headers), do: headers

  defp process_url(endpoint, %Hunter.Client{base_url: base_url}) do
    process_url(endpoint, base_url)
  end

  defp process_url(endpoint, base_url) when is_binary(base_url) do
    base_url <> endpoint
  end

  defp transform(body, :account) do
    Poison.decode!(body, as: %Hunter.Account{})
  end

  defp transform(body, :accounts) do
    Poison.decode!(body, as: [%Hunter.Account{}])
  end

  defp transform(body, :application) do
    Poison.decode!(body, as: %Hunter.Application{})
  end

  defp transform(body, :attachment) do
    Poison.decode!(body, as: %Hunter.Attachment{})
  end

  defp transform(body, :card) do
    Poison.decode!(body, as: %Hunter.Card{})
  end

  defp transform(body, :context) do
    Poison.decode!(
      body,
      as: %Hunter.Context{ancestors: [%Hunter.Status{}], descendants: [%Hunter.Status{}]}
    )
  end

  defp transform(body, :instance) do
    Poison.decode!(body, as: %Hunter.Instance{})
  end

  defp transform(body, :notification) do
    Poison.decode!(body, as: notification_nested_struct())
  end

  defp transform(body, :notifications) do
    Poison.decode!(body, as: [notification_nested_struct()])
  end

  defp transform(body, :status) do
    Poison.decode!(body, as: status_nested_struct())
  end

  defp transform(body, :statuses) do
    Poison.decode!(body, as: [status_nested_struct()])
  end

  defp transform(body, :relationship) do
    Poison.decode!(body, as: %Hunter.Relationship{})
  end

  defp transform(body, :relationships) do
    Poison.decode!(body, as: [%Hunter.Relationship{}])
  end

  defp transform(body, :report) do
    Poison.decode!(body, as: %Hunter.Report{})
  end

  defp transform(body, :reports) do
    Poison.decode!(body, as: [%Hunter.Report{}])
  end

  defp transform(body, :result) do
    Poison.decode!(
      body,
      as: %Hunter.Result{accounts: [%Hunter.Account{}], statuses: [%Hunter.Status{}]}
    )
  end

  defp transform(body, _) do
    Poison.decode!(body)
  end

  defp status_nested_struct do
    %Hunter.Status{
      account: %Hunter.Account{},
      reblog: %Hunter.Status{},
      media_attachments: [%Hunter.Attachment{}],
      mentions: [%Hunter.Mention{}],
      tags: [%Hunter.Tag{}],
      application: %Hunter.Application{}
    }
  end

  defp notification_nested_struct do
    %Hunter.Notification{
      account: %Hunter.Account{},
      status: %Hunter.Status{}
    }
  end
end
