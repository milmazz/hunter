defmodule Hunter.ClientTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Client

  describe "new/1" do
    test "builds a client with the given options" do
      conn = Hunter.new(base_url: "https://example.com", access_token: "123456")

      assert %Client{base_url: "https://example.com", access_token: "123456"} = conn
    end
  end

  test "user_agent/0 advertises hunter and its version" do
    assert Hunter.user_agent() == "Hunter.Elixir/#{Hunter.version()}"
  end
end
