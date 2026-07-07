defmodule Hunter.DomainTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Domain

  @conn Hunter.Client.new(base_url: "https://example.com", access_token: "123456")

  setup :verify_on_exit!

  test "returns blocked domains" do
    expect(Hunter.ApiMock, :blocked_domains, fn %Hunter.Client{}, [] ->
      ["spam.example"]
    end)

    assert ["spam.example"] = Domain.blocked_domains(@conn)
  end

  test "blocks and unblocks a domain" do
    expect(Hunter.ApiMock, :block_domain, fn %Hunter.Client{}, "spam.example" -> true end)
    expect(Hunter.ApiMock, :unblock_domain, fn %Hunter.Client{}, "spam.example" -> true end)

    assert Domain.block_domain(@conn, "spam.example")
    assert Domain.unblock_domain(@conn, "spam.example")
  end
end
