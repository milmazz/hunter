defmodule Hunter.Api.HTTPClient do
  @moduledoc """
  HTTP Client for Hunter
  """

  alias Hunter.Api.Request

  def verify_credentials(conn) do
    Request.request!(conn, :get, "/api/v1/accounts/verify_credentials", :account)
  end

  def update_credentials(conn, data) do
    Request.request!(conn, :patch, "/api/v1/accounts/update_credentials", :account, data)
  end

  def account(conn, id) do
    Request.request!(conn, :get, "/api/v1/accounts/#{id}", :account)
  end

  def followers(conn, id, options) do
    Request.request!(conn, :get, "/api/v1/accounts/#{id}/followers", :accounts, options)
  end

  def following(conn, id, options) do
    Request.request!(conn, :get, "/api/v1/accounts/#{id}/following", :accounts, options)
  end

  def search_account(conn, options) do
    Request.request!(conn, :get, "/api/v1/accounts/search", :accounts, options)
  end

  def blocks(conn, options) do
    Request.request!(conn, :get, "/api/v1/blocks", :accounts, options)
  end

  def follow_requests(conn, options) do
    Request.request!(conn, :get, "/api/v1/follow_requests", :accounts, options)
  end

  def mutes(conn, options) do
    Request.request!(conn, :get, "/api/v1/mutes", :accounts, options)
  end

  def follow_request_action(conn, id, action) when action in [:authorize, :reject] do
    Request.request!(conn, :post, "/api/v1/follow_requests/#{id}/#{action}", :relationship)
  end

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

  def relationships(conn, ids) do
    Request.request!(conn, :get, "/api/v1/accounts/relationships", :relationships, %{id: ids})
  end

  def follow(conn, id) do
    Request.request!(conn, :post, "/api/v1/accounts/#{id}/follow", :relationship)
  end

  def unfollow(conn, id) do
    Request.request!(conn, :post, "/api/v1/accounts/#{id}/unfollow", :relationship)
  end

  def block(conn, id) do
    Request.request!(conn, :post, "/api/v1/accounts/#{id}/block", :relationship)
  end

  def unblock(conn, id) do
    Request.request!(conn, :post, "/api/v1/accounts/#{id}/unblock", :relationship)
  end

  def mute(conn, id) do
    Request.request!(conn, :post, "/api/v1/accounts/#{id}/mute", :relationship)
  end

  def unmute(conn, id) do
    Request.request!(conn, :post, "/api/v1/accounts/#{id}/unmute", :relationship)
  end

  def search(conn, query, options) do
    options = options |> Keyword.merge(q: query) |> Map.new()

    Request.request!(conn, :get, "/api/v2/search", :result, options)
  end

  def create_status(conn, status, options) do
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

  def poll(conn, id) do
    Request.request!(conn, :get, "/api/v1/polls/#{id}", :poll)
  end

  def vote(conn, id, choices) do
    Request.request!(conn, :post, "/api/v1/polls/#{id}/votes", :poll, %{choices: choices})
  end

  def status(conn, id) do
    Request.request!(conn, :get, "/api/v1/statuses/#{id}", :status)
  end

  def destroy_status(conn, id) do
    Request.request!(conn, :delete, "/api/v1/statuses/#{id}", :empty)
  end

  def statuses_by_ids(conn, ids) do
    Request.request!(conn, :get, "/api/v1/statuses", :statuses, %{id: ids})
  end

  def edit_status(conn, id, status, options) do
    body = options |> Keyword.put(:status, status) |> Map.new()

    Request.request!(conn, :put, "/api/v1/statuses/#{id}", :status, body)
  end

  def status_history(conn, id) do
    Request.request!(conn, :get, "/api/v1/statuses/#{id}/history", :status_edits)
  end

  def status_source(conn, id) do
    Request.request!(conn, :get, "/api/v1/statuses/#{id}/source", :status_source)
  end

  def bookmark(conn, id), do: status_action(conn, id, :bookmark)

  def unbookmark(conn, id), do: status_action(conn, id, :unbookmark)

  def pin(conn, id), do: status_action(conn, id, :pin)

  def unpin(conn, id), do: status_action(conn, id, :unpin)

  def mute_conversation(conn, id), do: status_action(conn, id, :mute)

  def unmute_conversation(conn, id), do: status_action(conn, id, :unmute)

  defp status_action(conn, id, action) do
    Request.request!(conn, :post, "/api/v1/statuses/#{id}/#{action}", :status)
  end

  def bookmarks(conn, options) do
    Request.request!(conn, :get, "/api/v1/bookmarks", :statuses, options)
  end

  def translate_status(conn, id, options) do
    Request.request!(
      conn,
      :post,
      "/api/v1/statuses/#{id}/translate",
      :translation,
      Map.new(options)
    )
  end

  def reblog(conn, id) do
    Request.request!(conn, :post, "/api/v1/statuses/#{id}/reblog", :status)
  end

  def unreblog(conn, id) do
    Request.request!(conn, :post, "/api/v1/statuses/#{id}/unreblog", :status)
  end

  def reblogged_by(conn, id, options) do
    Request.request!(conn, :get, "/api/v1/statuses/#{id}/reblogged_by", :accounts, options)
  end

  def favourite(conn, id) do
    Request.request!(conn, :post, "/api/v1/statuses/#{id}/favourite", :status)
  end

  def unfavourite(conn, id) do
    Request.request!(conn, :post, "/api/v1/statuses/#{id}/unfavourite", :status)
  end

  def favourites(conn, options) do
    Request.request!(conn, :get, "/api/v1/favourites", :statuses, options)
  end

  def favourited_by(conn, id, options) do
    Request.request!(conn, :get, "/api/v1/statuses/#{id}/favourited_by", :accounts, options)
  end

  def statuses(conn, account_id, options) do
    Request.request!(conn, :get, "/api/v1/accounts/#{account_id}/statuses", :statuses, options)
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

  defp retrieve_timeline(conn, endpoint, options) do
    Request.request!(conn, :get, endpoint, :statuses, options)
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

  def status_context(conn, id) do
    Request.request!(conn, :get, "/api/v1/statuses/#{id}/context", :context)
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
