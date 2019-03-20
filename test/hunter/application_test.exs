defmodule Hunter.ApplicationTest do
  use ExUnit.Case, async: true

  import Mox

  setup :verify_on_exit!

  test "should allow to create an app" do
    expect(Hunter.ApiMock, :create_app, fn _client, _redirect, _scopes, _website, _opts ->
      %Hunter.Application{client_id: "1234567890", client_secret: "1234567890", id: 1234}
    end)

    assert %Hunter.Application{client_id: "1234567890", client_secret: "1234567890", id: 1234} ==
             Hunter.Application.create_app(
               "hunter",
               "urn:ietf:wg:oauth:2.0:oob",
               ["read", "write", "follow"],
               nil,
               save?: false,
               api_base_url: "https://example.com"
             )
  end

  test "should allow to store credentials on home directory" do
    expect(Hunter.ApiMock, :create_app, fn _client, _redirect, _scopes, _website, _opts ->
      %Hunter.Application{client_id: "1234567890", client_secret: "1234567890", id: 1234}
    end)

    home = Hunter.Config.home()
    tmp_dir = Path.expand("../../tmp", __DIR__)
    Application.put_env(:hunter, :home, tmp_dir)
    app_name = "hunter"

    assert %Hunter.Application{client_id: "1234567890", client_secret: "1234567890", id: 1234} =
             result =
             Hunter.Application.create_app(
               app_name,
               "urn:ietf:wg:oauth:2.0:oob",
               ["read"],
               nil,
               save?: true,
               api_base_url: "https://example.com"
             )

    assert result == Hunter.Application.load_credentials(app_name)
    Application.put_env(:hunter, :home, home)
  end

  test "should allow to load persisted app's credentials" do
    home = Hunter.Config.home()
    tmp_dir = Path.expand("../../tmp", __DIR__)
    app_dir = Path.join(tmp_dir, "apps")
    app_name = "load"
    Application.put_env(:hunter, :home, tmp_dir)

    expected = %{id: 1234, client_secret: "1234567890", client_id: "1234567890"}

    unless File.exists?(app_dir), do: File.mkdir_p!(app_dir)

    File.write!("#{app_dir}/#{app_name}.json", Poison.encode!(expected))

    assert %Hunter.Application{} = app = Hunter.Application.load_credentials(app_name)

    assert Map.equal?(Map.from_struct(app), expected)

    Application.put_env(:hunter, :home, home)
  end
end
