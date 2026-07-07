defmodule Hunter.ConfigTest do
  use ExUnit.Case, async: false

  alias Hunter.Config

  test "home/0 prefers the HUNTER_HOME environment variable" do
    previous = System.get_env("HUNTER_HOME")
    System.put_env("HUNTER_HOME", "/tmp/hunter-home")

    assert Config.home() == "/tmp/hunter-home"

    if previous do
      System.put_env("HUNTER_HOME", previous)
    else
      System.delete_env("HUNTER_HOME")
    end
  end

  test "hunter_api/0 falls back to the HTTP client when unconfigured" do
    Application.delete_env(:hunter, :hunter_api)

    try do
      assert Config.hunter_api() == Hunter.Api.HTTPClient
    after
      Application.put_env(:hunter, :hunter_api, Hunter.ApiMock)
    end
  end
end
