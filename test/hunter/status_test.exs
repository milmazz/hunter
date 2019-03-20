defmodule Hunter.StatusTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Status

  @conn Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")

  setup :verify_on_exit!

  test "home timeline should return a collection of statuses" do
    expect(Hunter.ApiMock, :home_timeline, fn _conn, _opts ->
      [%Hunter.Status{}]
    end)

    assert [timeline | []] = Status.home_timeline(@conn, limit: 1)
  end

  test "public time should return a collection of statuses" do
    expect(Hunter.ApiMock, :public_timeline, fn _conn, _opts ->
      [%Hunter.Status{}]
    end)

    assert [timeline | []] = Status.public_timeline(@conn, limit: 1, local: true)
  end
end
