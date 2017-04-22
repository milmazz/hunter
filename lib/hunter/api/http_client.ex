defmodule Hunter.Api.HTTPClient do
  @moduledoc """
  HTTP Client for Hunter
  """

  alias Hunter.Request

  @behaviour Hunter.Api

  def verify_credentials(conn) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/accounts/verify_credentials"), [], get_headers(conn))
    |> transform(:account)
  end

  def update_credentials(conn, data) do
    :patch
    |> Request.request!(process_url(conn, "/api/v1/accounts/update_credentials"), data, get_headers(conn))
    |> transform(:account)
  end

  def account(conn, id) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/accounts/#{id}"), [], get_headers(conn))
    |> transform(:account)
  end

  def followers(conn, id) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/accounts/#{id}/followers"), [], get_headers(conn))
    |> transform(:accounts)
  end

  def following(conn, id) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/accounts/#{id}/following"), [], get_headers(conn))
    |> transform(:accounts)
  end

  def follow_by_uri(conn, uri) do
    :post
    |> Request.request!(process_url(conn, "/api/v1/follows"), %{uri: uri}, get_headers(conn))
    |> transform(:account)
  end

  def search_account(conn, options) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/accounts/search"), options, get_headers(conn))
    |> transform(:accounts)
  end

  def blocks(conn) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/blocks"), [], get_headers(conn))
    |> transform(:accounts)
  end

  def follow_requests(conn) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/follow_requests"), [], get_headers(conn))
    |> transform(:accounts)
  end

  def mutes(conn) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/mutes"), [], get_headers(conn))
    |> transform(:accounts)
  end

  def follow_request_action(conn, id, action) when action in [:authorize, :reject] do
    Request.request!(:post, process_url(conn, "/api/v1/follow_requests/#{action}"), %{id: id}, get_headers(conn))
    true
  end

  def create_app(name, redirect_uri, scopes, website, base_url) do
    payload = %{
      client_name: name,
      redirect_uris: redirect_uri,
      scopes: Enum.join(scopes, " "),
      website: website,
    }

    :post
    |> Request.request!(process_url(base_url, "/api/v1/apps"), payload)
    |> transform(:application)
  end

  # TODO: Review this function
  def upload_media(conn, file) do
    :post
    |> Request.request!(process_url(conn, "/api/v1/media"), {:file, file}, get_headers(conn))
    |> transform(:attachment)
  end

  def relationships(conn, ids) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/accounts/relationships"), %{id: ids}, get_headers(conn))
    |> transform(:relationships)
  end

  def follow(conn, id) do
    :post
    |> Request.request!(process_url(conn, "/api/v1/accounts/#{id}/follow"), [], get_headers(conn))
    |> transform(:relationship)
  end

  def unfollow(conn, id) do
    :post
    |> Request.request!(process_url(conn, "/api/v1/accounts/#{id}/unfollow"), [], get_headers(conn))
    |> transform(:relationship)
  end

  def block(conn, id) do
    :post
    |> Request.request!(process_url(conn, "/api/v1/accounts/#{id}/block"), [], get_headers(conn))
    |> transform(:relationship)
  end

  def unblock(conn, id) do
    :post
    |> Request.request!(process_url(conn, "/api/v1/accounts/#{id}/unblock"), [], get_headers(conn))
    |> transform(:relationship)
  end

  def mute(conn, id) do
    :post
    |> Request.request!(process_url(conn, "/api/v1/accounts/#{id}/mute"), [], get_headers(conn))
    |> transform(:relationship)
  end

  def unmute(conn, id) do
    :post
    |> Request.request!(process_url(conn, "/api/v1/accounts/#{id}/unmute"), [], get_headers(conn))
    |> transform(:relationship)
  end

  def search(conn, query, options) do
    options = options |> Keyword.merge([q: query]) |> Map.new()

    :get
    |> Request.request!(process_url(conn, "/api/v1/search"), options, get_headers(conn))
    |> transform(:result)
  end

  def create_status(conn, status, options) do
    body = Map.put(options, :status, status)

    :post
    |> Request.request!(process_url(conn, "/api/v1/statuses"), body, get_headers(conn))
    |> transform(:status)
  end

  def status(conn, id) do
    :get!
    |> Request.request!(process_url(conn, "/api/v1/statuses/#{id}"), [], get_headers(conn))
    |> transform(:status)
  end

  def destroy_status(conn, id) do
    Request.request!(:delete, process_url(conn, "/api/v1/statuses/#{id}"), [], get_headers(conn))

    true
  end

  def reblog(conn, id) do
    :post
    |> Request.request!(process_url(conn, "/api/v1/statuses/#{id}/reblog"), [], get_headers(conn))
    |> transform(:status)
  end

  def unreblog(conn, id) do
    :post
    |> Request.request!(process_url(conn, "/api/v1/statuses/#{id}/unreblog"), [], get_headers(conn))
    |> transform(:status)
  end

  def reblogged_by(conn, id) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/statuses/#{id}/reblogged_by"), [], get_headers(conn))
    |> transform(:accounts)
  end

  def favourite(conn, id) do
    :post
    |> Request.request!(process_url(conn, "/api/v1/statuses/#{id}/favourite"), [], get_headers(conn))
    |> transform(:status)
  end

  def unfavourite(conn, id) do
    :post
    |> Request.request!(process_url(conn, "/api/v1/statuses/#{id}/unfavourite"), [], get_headers(conn))
    |> transform(:status)
  end

  def favourites(conn) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/favourites"), [], get_headers(conn))
    |> transform(:statuses)
  end

  def favourited_by(conn, id) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/statuses/#{id}/favourited_by"), [], get_headers(conn))
    |> transform(:accounts)
  end

  def statuses(conn, account_id, options) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/accounts/#{account_id}/statuses"), options, get_headers(conn))
    |> transform(:statuses)
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

  defp retrieve_timeline(conn, url, options) do
    :get
    |> Request.request!(process_url(conn, url), options, get_headers(conn))
    |> transform(:statuses)
  end

  def instance_info(conn) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/instance"), [], get_headers(conn))
    |> transform(:instance)
  end

  def notifications(conn) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/notifications"), [], get_headers(conn))
    |> transform(:notifications)
  end

  def notification(conn, id) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/notifications/#{id}"), [], get_headers(conn))
    |> transform(:notification)
  end

  def clear_notifications(conn) do
    Request.request!(:post, process_url(conn, "/api/v1/notifications/clear"), [], get_headers(conn))
    true
  end

  def reports(conn) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/reports"), [], get_headers(conn))
    |> transform(:reports)
  end

  def report(conn, account_id, status_ids, comment) do
    payload = %{
      account_id: account_id,
      status_ids: status_ids,
      comment: comment
    }

    :post
    |> Request.request!(process_url(conn, "/api/v1/reports"), payload, get_headers(conn))
    |> transform(:report)
  end

  def status_context(conn, id) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/statuses/#{id}/context"), [], get_headers(conn))
    |> transform(:context)
  end

  def card_by_status(conn, id) do
    :get
    |> Request.request!(process_url(conn, "/api/v1/statuses/#{id}/card"), [], get_headers(conn))
    |> transform(:card)
  end

  def log_in(%Hunter.Application{client_id: client_id, client_secret: client_secret}, username, password, base_url) do
    payload = %{
      client_id: client_id,
      client_secret: client_secret,
      grant_type: "password",
      username: username,
      password: password
    }

    response =
      :post
      |> Request.request!(process_url(base_url, "/oauth/token"), payload)
      |> Poison.decode!()

    %Hunter.Client{base_url: base_url, bearer_token: response["access_token"]}
  end

  ## Helpers
  defp get_headers(%Hunter.Client{bearer_token: token}) do
    ["Authorization": "Bearer #{token}"]
  end

  defp process_url(%Hunter.Client{base_url: base_url}, url) do
    process_url(base_url, url)
  end

  defp process_url(base_url, url) when is_binary(base_url) do
    base_url <> url
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
    Poison.decode!(body, as: %Hunter.Context{ancestors: [%Hunter.Status{}], descendants: [%Hunter.Status{}]})
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
    Poison.decode!(body, as: %Hunter.Result{accounts: [%Hunter.Account{}], statuses: [%Hunter.Status{}]})
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
