defmodule Hunter.IntegrationCase do
  @moduledoc """
  Case template for tests that run against a real Mastodon server.

  Requires `HUNTER_BASE_URL`, `HUNTER_TOKEN`, `HUNTER_TOKEN2`,
  `HUNTER_PASSWORD2`, `HUNTER_OAUTH_CLIENT_ID`, `HUNTER_OAUTH_CLIENT_SECRET`
  and `HUNTER_OAUTH_CODE` to be set; run via `mix test --only integration` so
  the mock-based unit suite does not run concurrently (the API adapter is
  swapped globally). The OAuth authorization code is single-use — re-run
  `scripts/ci/setup_mastodon.sh` before re-running the suite.
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
    oauth_client_id = fetch_env!("HUNTER_OAUTH_CLIENT_ID")
    oauth_client_secret = fetch_env!("HUNTER_OAUTH_CLIENT_SECRET")
    oauth_code = fetch_env!("HUNTER_OAUTH_CODE")

    previous_api = Application.get_env(:hunter, :hunter_api)
    previous_req = Application.get_env(:hunter, :req_options)

    Application.put_env(:hunter, :hunter_api, Hunter.Api.HTTPClient)
    # The CI stack fronts Mastodon with a self-signed TLS cert; disable
    # certificate verification on the Mint transport.
    Application.put_env(:hunter, :req_options,
      connect_options: [transport_opts: [verify: :verify_none]],
      receive_timeout: 30_000
    )

    on_exit(fn ->
      restore_env(:hunter_api, previous_api)
      restore_env(:req_options, previous_req)
    end)

    {:ok,
     conn: Hunter.Client.new(base_url: base_url, access_token: token),
     conn2: Hunter.Client.new(base_url: base_url, access_token: token2),
     password2: password2,
     oauth_client_id: oauth_client_id,
     oauth_client_secret: oauth_client_secret,
     oauth_code: oauth_code}
  end

  @doc """
  Retries `fun` until it returns without raising, for async server-side
  effects (sidekiq). Raises the last error after `attempts` tries.
  """
  def eventually(fun, attempts \\ 30)

  def eventually(fun, attempts) when attempts <= 1, do: fun.()

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
