defmodule Hunter.Api.Request do
  @moduledoc false

  def request(http_method, url, data \\ [], headers \\ [], options \\ []) do
    {body, params} = split_payload(http_method, data)
    headers = process_request_header(headers)
    options = attach_params(options, params)

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
  def split_payload(method, data) when method in [:get, :delete] do
    {"", encode_params(data)}
  end

  def split_payload(_method, data), do: {process_request_body(data), []}

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

  defp attach_params(options, []), do: options
  defp attach_params(options, params), do: Keyword.put(options, :params, params)

  defp encode_params(data) do
    Enum.flat_map(data, fn
      {key, values} when is_list(values) -> Enum.map(values, &{"#{key}[]", to_string(&1)})
      {key, value} -> [{to_string(key), to_string(value)}]
    end)
  end
end
