defmodule Hunter.Api.HTTPClient do
  @moduledoc """
  HTTP Client for Hunter
  """

  alias Hunter.Api.Request

  def upload_media(conn, file, options) do
    # stream raw byte chunks (Elixir 1.16+ argument order): the default line
    # mode rewrites \r\n and transmits fewer bytes than the declared
    # content-length
    parts =
      [file: {File.stream!(file, 65_536), filename: Path.basename(file)}] ++
        Enum.map(options, fn {key, value} -> {key, to_string(value)} end)

    Request.request!(conn, :post, "/api/v2/media", :attachment, {:form_multipart, parts})
  end

  def media_attachment(conn, id) do
    Request.request!(conn, :get, "/api/v1/media/#{id}", :attachment)
  end

  def update_media(conn, id, options) do
    Request.request!(conn, :put, "/api/v1/media/#{id}", :attachment, Map.new(options))
  end

  def delete_media(conn, id) do
    Request.request!(conn, :delete, "/api/v1/media/#{id}", :empty)
  end

  def lists(conn) do
    Request.request!(conn, :get, "/api/v1/lists", :lists)
  end

  def list(conn, id) do
    Request.request!(conn, :get, "/api/v1/lists/#{id}", :list)
  end

  def create_list(conn, title, options) do
    body = options |> Keyword.put(:title, title) |> Map.new()

    Request.request!(conn, :post, "/api/v1/lists", :list, body)
  end

  def update_list(conn, id, options) do
    Request.request!(conn, :put, "/api/v1/lists/#{id}", :list, Map.new(options))
  end

  def destroy_list(conn, id) do
    Request.request!(conn, :delete, "/api/v1/lists/#{id}", :empty)
  end

  def list_accounts(conn, id, options) do
    Request.request!(conn, :get, "/api/v1/lists/#{id}/accounts", :accounts, options)
  end

  def add_accounts_to_list(conn, id, account_ids) do
    Request.request!(conn, :post, "/api/v1/lists/#{id}/accounts", :empty, %{
      account_ids: account_ids
    })
  end

  def remove_accounts_from_list(conn, id, account_ids) do
    Request.request!(conn, :delete, "/api/v1/lists/#{id}/accounts", :empty, %{
      account_ids: account_ids
    })
  end

  def account_lists(conn, account_id) do
    Request.request!(conn, :get, "/api/v1/accounts/#{account_id}/lists", :lists)
  end

  def instance_info(conn) do
    Request.request!(conn, :get, "/api/v2/instance", :instance)
  end

  def notifications(conn, options) do
    Request.request!(conn, :get, "/api/v1/notifications", :notifications, options)
  end

  def notification(conn, id) do
    Request.request!(conn, :get, "/api/v1/notifications/#{id}", :notification)
  end

  def clear_notifications(conn) do
    Request.request!(conn, :post, "/api/v1/notifications/clear", :empty)
  end

  def clear_notification(conn, id) do
    Request.request!(conn, :post, "/api/v1/notifications/#{id}/dismiss", :empty)
  end

  def unread_count(conn) do
    Request.request!(conn, :get, "/api/v1/notifications/unread_count", nil)
    |> Map.fetch!("count")
  end

  def notification_policy(conn) do
    Request.request!(conn, :get, "/api/v2/notifications/policy", :notification_policy)
  end

  def update_notification_policy(conn, options) do
    Request.request!(
      conn,
      :patch,
      "/api/v2/notifications/policy",
      :notification_policy,
      Map.new(options)
    )
  end

  def notification_requests(conn, options) do
    Request.request!(
      conn,
      :get,
      "/api/v1/notifications/requests",
      :notification_requests,
      options
    )
  end

  def notification_request(conn, id) do
    Request.request!(conn, :get, "/api/v1/notifications/requests/#{id}", :notification_request)
  end

  def accept_notification_request(conn, id) do
    Request.request!(conn, :post, "/api/v1/notifications/requests/#{id}/accept", :empty)
  end

  def dismiss_notification_request(conn, id) do
    Request.request!(conn, :post, "/api/v1/notifications/requests/#{id}/dismiss", :empty)
  end

  def accept_notification_requests(conn, ids) do
    Request.request!(conn, :post, "/api/v1/notifications/requests/accept", :empty, %{id: ids})
  end

  def dismiss_notification_requests(conn, ids) do
    Request.request!(conn, :post, "/api/v1/notifications/requests/dismiss", :empty, %{id: ids})
  end

  def notification_requests_merged?(conn) do
    Request.request!(conn, :get, "/api/v1/notifications/requests/merged", nil)
    |> Map.fetch!("merged")
  end

  def grouped_notifications(conn, options) do
    Request.request!(conn, :get, "/api/v2/notifications", :grouped_notifications, options)
  end

  def notification_group(conn, group_key) do
    Request.request!(conn, :get, "/api/v2/notifications/#{group_key}", :grouped_notifications)
  end

  def dismiss_notification_group(conn, group_key) do
    Request.request!(conn, :post, "/api/v2/notifications/#{group_key}/dismiss", :empty)
  end

  def notification_group_accounts(conn, group_key) do
    Request.request!(conn, :get, "/api/v2/notifications/#{group_key}/accounts", :accounts)
  end

  def grouped_unread_count(conn) do
    Request.request!(conn, :get, "/api/v2/notifications/unread_count", nil)
    |> Map.fetch!("count")
  end

  def create_push_subscription(conn, subscription, data) do
    Request.request!(conn, :post, "/api/v1/push/subscription", :web_push_subscription, %{
      subscription: subscription,
      data: data
    })
  end

  def push_subscription(conn) do
    Request.request!(conn, :get, "/api/v1/push/subscription", :web_push_subscription)
  end

  def update_push_subscription(conn, data) do
    Request.request!(conn, :put, "/api/v1/push/subscription", :web_push_subscription, %{
      data: data
    })
  end

  def delete_push_subscription(conn) do
    Request.request!(conn, :delete, "/api/v1/push/subscription", :empty)
  end

  def report(conn, account_id, status_ids, comment) do
    payload = %{
      account_id: account_id,
      status_ids: status_ids,
      comment: comment
    }

    Request.request!(conn, :post, "/api/v1/reports", :report, payload)
  end

  def blocked_domains(conn, options) do
    Request.request!(conn, :get, "/api/v1/domain_blocks", nil, options)
  end

  def block_domain(conn, domain) do
    Request.request!(conn, :post, "/api/v1/domain_blocks", :empty, %{domain: domain})
  end

  def unblock_domain(conn, domain) do
    Request.request!(conn, :delete, "/api/v1/domain_blocks", :empty, %{domain: domain})
  end
end
