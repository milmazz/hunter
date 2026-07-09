defmodule Hunter.Api.Request do
  @moduledoc false

  def request(http_method, url, data \\ [], headers \\ [], options \\ []) do
    {body_options, params} = split_payload(http_method, data)

    headers =
      headers
      |> process_request_header()
      |> add_content_type(body_options)

    [
      method: http_method,
      url: url,
      headers: headers,
      # entity decoding happens in Hunter.Api.Transformer, off the raw body
      decode_body: false,
      retry: false
    ]
    |> Keyword.merge(body_options)
    |> attach_params(params)
    |> Keyword.merge(options)
    |> Req.request()
    |> handle_response()
  end

  def request!(http_method, url, data \\ [], headers \\ [], options \\ []) do
    case request(http_method, url, data, headers, options) do
      {:ok, body} -> body
      {:error, reason} -> raise Hunter.Error, reason: reason
    end
  end

  @doc false
  def handle_response({:ok, %Req.Response{status: status, body: body}})
      when status in 200..299 do
    {:ok, body}
  end

  def handle_response({:ok, %Req.Response{body: body}}), do: {:error, body}

  def handle_response({:error, %{reason: reason}}), do: {:error, reason}

  def handle_response({:error, exception}), do: {:error, Exception.message(exception)}

  @doc false
  def split_payload(method, data) when method in [:get, :delete] do
    {[], encode_params(data)}
  end

  def split_payload(_method, {:form_multipart, parts}), do: {[form_multipart: parts], []}

  def split_payload(_method, data), do: {[body: process_request_body(data)], []}

  @doc false
  def process_request_body([]), do: "{}"
  def process_request_body(data) when is_binary(data), do: data
  def process_request_body(data), do: Poison.encode!(data)

  @doc false
  def process_request_header(headers) do
    Enum.reduce(headers, [{"accept", "application/json; charset=utf-8"}], fn {name, value}, acc ->
      List.keystore(acc, name, 0, {name, value})
    end)
  end

  # Req sets the multipart content type (with boundary) itself
  defp add_content_type(headers, body: _) do
    case List.keyfind(headers, "content-type", 0) do
      nil -> [{"content-type", "application/json"} | headers]
      _set_by_caller -> headers
    end
  end

  defp add_content_type(headers, _body_options), do: headers

  defp attach_params(options, []), do: options
  defp attach_params(options, params), do: Keyword.put(options, :params, params)

  defp encode_params(data) do
    Enum.flat_map(data, fn
      {key, values} when is_list(values) -> Enum.map(values, &{"#{key}[]", to_string(&1)})
      {key, value} -> [{to_string(key), to_string(value)}]
    end)
  end
end
