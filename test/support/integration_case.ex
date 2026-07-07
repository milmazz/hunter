defmodule Hunter.IntegrationCase do
  @moduledoc """
  Case template for tests that run against a real Mastodon server.

  Requires `HUNTER_BASE_URL`, `HUNTER_TOKEN`, `HUNTER_TOKEN2` and
  `HUNTER_PASSWORD2` to be set; run via `mix test --only integration` so the
  mock-based unit suite does not run concurrently (the API adapter is swapped
  globally).
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Hunter.IntegrationCase, only: [eventually: 1, eventually: 2]

      @moduletag :integration
      @moduletag timeout: 120_000
    end
  end

  setup_all do
    base_url = fetch_env!("HUNTER_BASE_URL")
    token = fetch_env!("HUNTER_TOKEN")
    token2 = fetch_env!("HUNTER_TOKEN2")
    password2 = fetch_env!("HUNTER_PASSWORD2")

    previous_api = Application.get_env(:hunter, :hunter_api)
    previous_http = Application.get_env(:hunter, :http_options)

    Application.put_env(:hunter, :hunter_api, Hunter.Api.HTTPClient)
    # The CI stack fronts Mastodon with a self-signed TLS cert. Disable
    # certificate verification; hackney's `:insecure` shortcut no longer takes
    # effect on OTP 26+, so pass the ssl option through directly.
    Application.put_env(:hunter, :http_options, ssl: [verify: :verify_none], recv_timeout: 30_000)

    on_exit(fn ->
      restore_env(:hunter_api, previous_api)
      restore_env(:http_options, previous_http)
    end)

    {:ok,
     conn: Hunter.Client.new(base_url: base_url, access_token: token),
     conn2: Hunter.Client.new(base_url: base_url, access_token: token2),
     password2: password2}
  end

  @doc """
  Retries `fun` until it returns without raising, for async server-side
  effects (sidekiq). Raises the last error after `attempts` tries.
  """
  def eventually(fun, attempts \\ 30)

  def eventually(fun, 1), do: fun.()

  def eventually(fun, attempts) do
    fun.()
  rescue
    _ ->
      Process.sleep(1_000)
      eventually(fun, attempts - 1)
  end

  defp restore_env(key, nil), do: Application.delete_env(:hunter, key)
  defp restore_env(key, value), do: Application.put_env(:hunter, key, value)

  defp fetch_env!(name) do
    System.get_env(name) ||
      raise """
      #{name} is not set.

      Integration tests need a running Mastodon server. Locally:

          ./scripts/ci/setup_mastodon.sh
          source scripts/ci/.env.hunter
          mix test --only integration
      """
  end
end
