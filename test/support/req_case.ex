defmodule Hunter.ReqCase do
  @moduledoc """
  Helpers for unit tests that stub the HTTP layer with `Req.Test`.

  The test environment routes every request through the `Hunter.ReqStub`
  plug (see `test_helper.exs`); tests install a per-process stub with
  `stub_request/1` and assert on the `Plug.Conn` the client produced.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Hunter.ReqCase
    end
  end

  @doc """
  Installs `fun` as this test's HTTP stub; `fun` receives the `Plug.Conn`
  and must return a response, typically via `respond_with/3` or
  `respond_with_fixture/3`.
  """
  def stub_request(fun), do: Req.Test.stub(Hunter.ReqStub, fun)

  @doc """
  Responds with the JSON fixture at `test/fixtures/<name>.json`. Wrap in a
  list with `wrap: :list` for endpoints returning collections.
  """
  def respond_with_fixture(conn, name, opts \\ []) do
    body =
      [__DIR__, "..", "fixtures", name <> ".json"]
      |> Path.join()
      |> Path.expand()
      |> File.read!()

    body = if opts[:wrap] == :list, do: "[" <> body <> "]", else: body

    respond_with(conn, body, opts[:status] || 200)
  end

  @doc """
  Responds with `data` as JSON (already-encoded binaries pass through).
  """
  def respond_with(conn, data, status \\ 200)

  def respond_with(conn, data, status) when is_binary(data) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, data)
  end

  def respond_with(conn, data, status), do: respond_with(conn, Poison.encode!(data), status)

  @doc """
  Reads and JSON-decodes the request body of `conn`.
  """
  def read_json_body!(conn) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    Poison.decode!(body)
  end
end
