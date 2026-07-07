defmodule Hunter.Api.Request do
  @moduledoc false

  def request(http_method, url, data \\ [], headers \\ [], options \\ []) do
    body = process_request_body(data)
    headers = process_request_header(headers)

    http_method
    |> HTTPoison.request(url, body, headers, options)
    |> handle_response()
  end

  def request!(http_method, url, data \\ [], headers \\ [], options \\ []) do
    case request(http_method, url, data, headers, options) do
      {:ok, body} -> body
      {:error, reason} -> raise Hunter.Error, reason: reason
    end
  end

  @doc false
  def handle_response({:ok, %{status_code: status, body: body}}) when status in 200..299 do
    {:ok, body}
  end

  def handle_response({:ok, %{body: body}}), do: {:error, body}

  def handle_response({:error, %HTTPoison.Error{reason: reason}}), do: {:error, reason}

  @doc false
  def process_request_body([]), do: "{}"
  def process_request_body({:multipart, _} = data), do: data
  def process_request_body(data) when is_binary(data), do: data
  def process_request_body(data), do: Poison.encode!(data)

  @doc false
  def process_request_header(data) do
    Keyword.merge(
      ["Content-Type": "application/json", Accept: "Application/json; Charset=utf-8"],
      data
    )
  end
end
