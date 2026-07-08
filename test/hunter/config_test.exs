defmodule Hunter.ConfigTest do
  use ExUnit.Case, async: false

  alias Hunter.Config

  test "home/0 prefers the HUNTER_HOME environment variable" do
    previous = System.get_env("HUNTER_HOME")
    System.put_env("HUNTER_HOME", "/tmp/hunter-home")

    try do
      assert Config.home() == "/tmp/hunter-home"
    after
      if previous do
        System.put_env("HUNTER_HOME", previous)
      else
        System.delete_env("HUNTER_HOME")
      end
    end
  end

  test "req_options/0 returns the configured Req options" do
    assert Config.req_options() == [plug: {Req.Test, Hunter.ReqStub}]
  end
end
