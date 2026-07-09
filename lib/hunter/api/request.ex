defmodule Hunter.Api.Request do
  @moduledoc """
  The single HTTP transport for Hunter.

  `request!/6` joins the endpoint path onto the base URL, sets
  authentication headers from the `Hunter.Client` (none for a bare base
  URL string), performs the request via `Req`, decodes the response
  through `Hunter.Api.Transformer`, and raises `Hunter.Error` on failure.
  """

  alias Hunter.{Api.Transformer, Config}

  @doc """
  Performs a request against the Mastodon API and returns the transformed
  entity.

  ## Parameters

    * `conn_or_base_url` - a `Hunter.Client` (authenticated) or a base URL
      string (unauthenticated, e.g. app registration and OAuth flows)
    * `method` - `:get`, `:post`, `:put`, `:patch` or `:delete`
    * `path` - endpoint path, e.g. `"/api/v1/statuses"`
    * `to` - `Hunter.Api.Transformer` target (e.g. `:status`, `:accounts`,
      `:empty`), or `nil` for the JSON-decoded body untouched
    * `payload` - query params for `:get`/`:delete`; JSON body (map or
      keyword) or `{:form_multipart, parts}` for write verbs
    * `opts` - `headers: [{name, value}]` extra request headers

  Raises `Hunter.Error` on non-2xx responses and transport errors.
  """
  def request!(conn_or_base_url, method, path, to, payload \\ [], opts \\ []) do
    url = url_for(conn_or_base_url, path)
    headers = auth_headers(conn_or_base_url) ++ Keyword.get(opts, :headers, [])

    case request(method, url, payload, headers, Config.req_options()) do
      {:ok, body} -> Transformer.transform(body, to)
      {:error, reason} -> raise Hunter.Error, reason: reason
    end
  end

  defp url_for(%Hunter.Client{base_url: base_url}, path), do: base_url <> path
  defp url_for(base_url, path) when is_binary(base_url), do: base_url <> path

  defp auth_headers(%Hunter.Client{access_token: token}),
    do: [{"authorization", "Bearer #{token}"}]

  defp auth_headers(base_url) when is_binary(base_url), do: []

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
