defmodule Hunter.ResultTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Result

  @conn Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")

  setup :verify_on_exit!

  test "searches for content" do
    expect(Hunter.ApiMock, :search, fn %Hunter.Client{}, "elixir", [] ->
      %Result{accounts: [], statuses: [], hashtags: ["elixir"]}
    end)

    assert %Result{hashtags: ["elixir"]} = Result.search(@conn, "elixir")
  end
end
