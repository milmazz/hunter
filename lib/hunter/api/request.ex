defmodule Hunter.Api.Request do
  @moduledoc false

  def request(http_method, url, data \\ [], headers \\ [], options \\ []) do
    body = process_request_body(data)
    headers = process_request_header(headers)

    make_request(http_method, url, body, headers, options)
  end

  def request!(http_method, url, data \\ [], headers \\ [], options \\ []) do
    case request(http_method, url, data, headers, options) do
      {:ok, body} -> body
      {:error, reason} -> raise Hunter.Error, reason: reason
    end
  end

  defp make_request(method, url, body, headers, options) do
    request = Finch.build(method, url, headers, body, options)

    case Finch.request(request, Mastodon) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %{body: body}} ->
        {:error, body}

      {:error, %{reason: reason}} ->
        {:error, reason}
    end
  end

  defp process_request_body(data) do
    case data do
      [] ->
        "{}"

      {:multipart, _} ->
        data

      data when is_binary(data) ->
        data

      _ ->
        Poison.encode!(data)
    end
  end

  defp process_request_header(data) do
    [{"Content-Type", "application/json"}, {"Accept", "Application/json; Charset=utf-8"} | data]
  end
end
