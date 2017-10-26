defmodule Hunter.StatusTest do
  use ExUnit.Case, async: true
  doctest Hunter.Status

  alias Hunter.Status

  setup do
    [conn: Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")]
  end

  test "home timeline should return a collection of statuses", %{conn: conn} do
    timeline = Status.home_timeline(conn, limit: 1)
    assert Enum.count(timeline) == 1
  end

  test "public time should return a collection of statuses", %{conn: conn} do
    timeline = Status.public_timeline(conn, limit: 1, local: true)
    assert Enum.count(timeline) == 1
  end
end
