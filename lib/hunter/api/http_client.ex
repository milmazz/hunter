defmodule Hunter.Api.HTTPClient do
  @moduledoc """
  HTTP Client for Hunter
  """

  @behaviour Hunter.Api

  def verify_credentials(%Hunter.Client{base_url: base_url} = conn) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/accounts/verify_credentials", get_headers(conn))
    Poison.decode!(body, as: %Hunter.Account{})
  end

  def account(%Hunter.Client{base_url: base_url} = conn, id) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/accounts/#{id}", get_headers(conn))
    Poison.decode!(body, as: %Hunter.Account{})
  end

  def followers(%Hunter.Client{base_url: base_url} = conn, id) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/accounts/#{id}/followers", get_headers(conn))
    Poison.decode!(body, as: [%Hunter.Account{}])
  end

  def following(%Hunter.Client{base_url: base_url} = conn, id) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/accounts/#{id}/following", get_headers(conn))
    Poison.decode!(body, as: [%Hunter.Account{}])
  end

  def follow_by_uri(%Hunter.Client{base_url: base_url} = conn, uri) do
    payload = Poison.encode!(%{uri: uri})

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/follows", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Account{})
  end

  def search_account(%Hunter.Client{base_url: base_url} = conn, options) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/accounts/search", [{"Content-Type", "application/json"} | get_headers(conn)], options)
    Poison.decode!(body, as: [%Hunter.Account{}])
  end

  def blocks(%Hunter.Client{base_url: base_url} = conn) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/blocks" , [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: [%Hunter.Account{}])
  end

  def follow_requests(%Hunter.Client{base_url: base_url} = conn) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/follow_requests" , [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: [%Hunter.Account{}])
  end

  def mutes(%Hunter.Client{base_url: base_url} = conn) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/mutes" , [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: [%Hunter.Account{}])
  end

  def create_app(%Hunter.Client{base_url: base_url} = conn, name, redirect_uri, scopes, website) do
    IO.puts redirect_uri
    payload = Poison.encode!(%{client_name: name, redirect_uris: redirect_uri, scopes: scopes, website: website})

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/apps", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Application{})
  end

  def upload_media(%Hunter.Client{base_url: base_url} = conn, file) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/media", {:file, file}, get_headers(conn))
    Poison.decode!(body, as: %Hunter.Attachment{})
  end

  def relationships(%Hunter.Client{base_url: base_url} = conn, ids) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/accounts/relationships", [{"Content-Type", "application/json"} | get_headers(conn)], [id: ids])

    Poison.decode!(body, as: [%Hunter.Relationship{}])
  end

  def follow(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/accounts/#{id}/follow", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Relationship{})
  end

  def unfollow(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/accounts/#{id}/unfollow", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Relationship{})
  end

  def block(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/accounts/#{id}/block", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Relationship{})
  end

  def unblock(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/accounts/#{id}/unblock", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Relationship{})
  end

  def mute(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/accounts/#{id}/mute", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Relationship{})
  end

  def unmute(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/accounts/#{id}/unmute", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Relationship{})
  end

  def search(%Hunter.Client{base_url: base_url} = conn, query, options) do
    options = Keyword.merge(options, [q: query])

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/search", get_headers(conn), options)
    Poison.decode!(body, as: %Hunter.Result{accounts: [%Hunter.Account{}], statuses: [%Hunter.Status{}]})
  end

  def create_status(%Hunter.Client{base_url: base_url} = conn, text, in_reply_to_id, _media_ids) do
    payload = Poison.encode!(%{status: text, in_reply_to_id: in_reply_to_id})

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/statuses", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    to_status(body)
  end

  def status(%Hunter.Client{base_url: base_url} = conn, id) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/statuses/#{id}", get_headers(conn))
    Poison.decode(body, as: %Hunter.Status{})
  end

  def destroy_status(%Hunter.Client{base_url: base_url} = conn, id) do
    case HTTPoison.delete(base_url <> "/api/v1/statuses/#{id}", get_headers(conn)) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        true
      _ ->
        false
    end
  end

  def reblog(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/statuses/#{id}/reblog", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    to_status(body)
  end

  def unreblog(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/statuses/#{id}/unreblog", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    to_status(body)
  end

  def reblogged_by(%Hunter.Client{base_url: base_url} = conn, id) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/statuses/#{id}/reblogged_by", get_headers(conn))
    to_accounts(body)
  end

  def favourite(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/statuses/#{id}/favourite", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    to_status(body)
  end

  def unfavourite(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/statuses/#{id}/unfavourite", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    to_status(body)
  end

  def favourites(%Hunter.Client{base_url: base_url} = conn) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/favourites", get_headers(conn))
    to_statuses(body)
  end

  def favourited_by(%Hunter.Client{base_url: base_url} = conn, id) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/statuses/#{id}/favourited_by", get_headers(conn))
    to_accounts(body)
  end

  @doc """
  Get an account's statuses

  ## Options

    * `only_media` - (optional): only return statuses that have media attachments
    * `exclude_replies` - (optional): skip statuses that reply to other statuses

  """
  def statuses(%Hunter.Client{base_url: base_url} = conn, account_id, options) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/accounts/#{account_id}/statuses", get_headers(conn), options)
    to_statuses(body)
  end

  def home_timeline(%Hunter.Client{base_url: base_url} = conn, options) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/timelines/home", get_headers(conn), options)
    to_statuses(body)
  end

  def public_timeline(%Hunter.Client{base_url: base_url} = conn, options) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/timelines/public", get_headers(conn), options)
    to_statuses(body)
  end

  def hashtag_timeline(%Hunter.Client{base_url: base_url} = conn, hashtag, options) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/timelines/tag/#{hashtag}", get_headers(conn), options)
    to_statuses(body)
  end

  @spec instance_info(Hunter.Client.t) :: Hunter.Instance.t
  def instance_info(%Hunter.Client{base_url: base_url} = conn) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/instance", get_headers(conn))
    Poison.decode!(body, as: %Hunter.Instance{})
  end

  def notifications(%Hunter.Client{base_url: base_url} = conn) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/notifications", get_headers(conn))
    to_notifications(body)
  end

  def notification(%Hunter.Client{base_url: base_url} = conn, id) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/notifications/#{id}", get_headers(conn))
    to_notification(body)
  end

  def clear_notifications(%Hunter.Client{base_url: base_url} = conn) do
    payload = Poison.encode!(%{})

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/notifications/clear", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    body
  end

  def reports(%Hunter.Client{base_url: base_url} = conn) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/reports", get_headers(conn))
    Poison.decode!(body, as: [%Hunter.Report{}])
  end

  def report(%Hunter.Client{base_url: base_url} = conn, account_id, status_ids, comment) do
    payload = Poison.encode!(%{
      account_id: account_id,
      status_ids: status_ids,
      comment: comment
    })

    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.post!(base_url <> "/api/v1/reports", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Report{})
  end

  def status_context(%Hunter.Client{base_url: base_url} = conn, id) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/statuses/#{id}/context", get_headers(conn))
    Poison.decode!(body, as: %Hunter.Context{ancestors: [%Hunter.Status{}], descendants: [%Hunter.Status{}]})
  end

  def card_by_status(%Hunter.Client{base_url: base_url} = conn, id) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(base_url <> "/api/v1/statuses/#{id}/card", get_headers(conn))
    Poison.decode!(body, as: %Hunter.Card{})
  end

  ## Helpers
  defp get_headers(%Hunter.Client{bearer_token: token}) do
    [{"Authorization", "Bearer #{token}"}]
  end

  defp to_status(body) do
    Poison.decode!(body, as: status_nested_struct())
  end

  defp to_statuses(body) do
    Poison.decode!(body, as: [status_nested_struct()])
  end

  defp to_accounts(body) do
    Poison.decode!(body, as: [%Hunter.Account{}])
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

  defp to_notification(body) do
    Poison.decode!(body, as: notification_nested_struct())
  end

  defp to_notifications(body) do
    Poison.decode!(body, as: [notification_nested_struct()])
  end

  defp notification_nested_struct do
    %Hunter.Notification{
      account: %Hunter.Account{},
      status: %Hunter.Status{}
    }
  end
end
