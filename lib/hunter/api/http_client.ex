defmodule Hunter.Api.HTTPClient do
  @moduledoc """
  HTTP Client for Hunter
  """

  @behaviour Hunter.Api

  def verify_credentials(%Hunter.Client{base_url: base_url} = conn) do
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.get(base_url <> "/api/v1/accounts/verify_credentials", get_headers(conn))
    Poison.decode!(body, as: %Hunter.Account{})
  end

  def account(%Hunter.Client{base_url: base_url} = conn, id) do
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.get(base_url <> "/api/v1/accounts/#{id}", get_headers(conn))
    Poison.decode!(body, as: %Hunter.Account{})
  end

  def followers(%Hunter.Client{base_url: base_url} = conn, id) do
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.get(base_url <> "/api/v1/accounts/#{id}/followers", get_headers(conn))
    Poison.decode!(body, as: [%Hunter.Account{}])
  end

  def following(%Hunter.Client{base_url: base_url} = conn, id) do
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.get(base_url <> "/api/v1/accounts/#{id}/following", get_headers(conn))
    Poison.decode!(body, as: [%Hunter.Account{}])
  end

  def follow_by_uri(%Hunter.Client{base_url: base_url} = conn, uri) do
    payload = Poison.encode!(%{uri: uri})

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.post(base_url <> "/api/v1/follows", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Account{})
  end

  def create_app(%Hunter.Client{base_url: base_url} = conn, name, redirect_uri, scopes, website) do
    payload = Poison.encode!(%{client_name: name, redirect_uris: redirect_uri, scopes: scopes, website: website})

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.post(base_url <> "/api/v1/apps", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Application{})
  end

  def upload_media(%Hunter.Client{base_url: base_url} = conn, file) do
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.post(base_url <> "/api/v1/media", {:file, file}, get_headers(conn))
    Poison.decode!(body, as: %Hunter.Attachment{})
  end

  def relationships(_ids) do
    # :: [Hunter.Relationship.t]
    # @return [Hunter::Collection<Hunter::Relationship>]
    # perform_request_with_collection(:get, '', array_param(:id, ids), Hunter::Relationship)
    HTTPoison.get("/api/v1/accounts/relationships")

    # Poison.decode!(body, as: [%Hunter.Relationship{}])
  end

  def follow(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.post(base_url <> "/api/v1/accounts/#{id}/follow", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Relationship{})
  end

  def unfollow(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.post(base_url <> "/api/v1/accounts/#{id}/unfollow", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Relationship{})
  end

  def block(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.post(base_url <> "/api/v1/accounts/#{id}/block", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Relationship{})
  end

  def unblock(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.post(base_url <> "/api/v1/accounts/#{id}/unblock", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Relationship{})
  end

  def mute(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.post(base_url <> "/api/v1/accounts/#{id}/mute", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Relationship{})
  end

  def unmute(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.post(base_url <> "/api/v1/accounts/#{id}/unmute", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Relationship{})
  end

  def search(_conn, _query, _options) do
    # :: Hunter.Result.t

    # @return [Hunter::Results] If q is a URL, Hunter will
    #   attempt to fetch the provided account or status. Otherwise, it
    #   will do a local account and hashtag search.

    # opts = {
    #   q: query,
    # }.merge(options)

    # perform_request_with_object(:get, '/api/v1/search', opts, Hunter::Results)
  end

  def create_status(%Hunter.Client{base_url: base_url} = conn, text, in_reply_to_id, _media_ids) do
    payload = Poison.encode!(%{status: text, in_reply_to_id: in_reply_to_id})

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.post(base_url <> "/api/v1/statuses", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Status{})
  end

  def status(%Hunter.Client{base_url: base_url} = conn, id) do
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.get(base_url <> "/api/v1/statuses/#{id}", get_headers(conn))
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

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.post(base_url <> "/api/v1/statuses/#{id}/reblog", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Status{})
  end

  def unreblog(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.post(base_url <> "/api/v1/statuses/#{id}/unreblog", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Status{})
  end

  def favourite(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.post(base_url <> "/api/v1/statuses/#{id}/favourite", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Status{})
  end

  def unfavourite(%Hunter.Client{base_url: base_url} = conn, id) do
    payload = Poison.encode!(%{})

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.post(base_url <> "/api/v1/statuses/#{id}/unfavourite", payload, [{"Content-Type", "application/json"} | get_headers(conn)])
    Poison.decode!(body, as: %Hunter.Status{})
  end

  def statuses(%Hunter.Client{base_url: base_url} = conn, account_id, options) do
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.get(base_url <> "/api/v1/accounts/#{account_id}/statuses", get_headers(conn), options)
    Poison.decode!(body, as: [%Hunter.Status{}])
  end

  def home_timeline(%Hunter.Client{base_url: base_url} = conn, options) do
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.get(base_url <> "/api/v1/timelines/home", get_headers(conn), options)
    Poison.decode!(body, as: [%Hunter.Status{}])
  end

  def public_timeline(%Hunter.Client{base_url: base_url} = conn, options) do
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.get(base_url <> "/api/v1/timelines/public", get_headers(conn), options)
    Poison.decode!(body, as: [%Hunter.Status{}])
  end

  def hashtag_timeline(%Hunter.Client{base_url: base_url} = conn, hashtag, options) do
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.get(base_url <> "/api/v1/timelines/tag/#{hashtag}", get_headers(conn), options)
    Poison.decode!(body, as: [%Hunter.Status{}])
  end

  ## Helpers
  defp get_headers(%Hunter.Client{bearer_token: token}) do
    [{"Authorization", "Bearer #{token}"}]
  end
end
