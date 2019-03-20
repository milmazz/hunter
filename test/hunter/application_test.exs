defmodule Hunter.ApplicationTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Application

  setup :verify_on_exit!

  test "should allow to create an app" do
    expect(Hunter.ApiMock, :create_app, fn _client, _redirect, _scopes, _website, _opts ->
      %Application{client_id: "1234567890", client_secret: "1234567890", id: 1234}
    end)

    assert %Application{client_id: "1234567890", client_secret: "1234567890", id: 1234} ==
             Application.create_app(
               "hunter",
               "urn:ietf:wg:oauth:2.0:oob",
               ["read", "write", "follow"],
               nil,
               save?: false,
               api_base_url: "https://example.com"
             )
  end
end
