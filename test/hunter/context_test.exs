defmodule Hunter.ContextTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Context

  @conn Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")

  setup :verify_on_exit!

  test "returns the context of a status" do
    expect(Hunter.ApiMock, :status_context, fn %Hunter.Client{}, 153_452 ->
      %Context{ancestors: [], descendants: [%Hunter.Status{id: "153453"}]}
    end)

    assert %Context{descendants: [%Hunter.Status{}]} = Context.status_context(@conn, 153_452)
  end
end
