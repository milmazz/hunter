defmodule Hunter.ApplicationTest do
  use Hunter.ReqCase, async: true

  test "registers an app with a JSON body and no auth header" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/apps"
      assert Plug.Conn.get_req_header(conn, "authorization") == []

      assert %{
               "client_name" => "hunter",
               "redirect_uris" => "urn:ietf:wg:oauth:2.0:oob",
               "scopes" => "read write follow",
               "website" => nil
             } = read_json_body!(conn)

      respond_with(conn, %{client_id: "1234567890", client_secret: "1234567890", id: 1234})
    end)

    assert %Hunter.Application{
             client_id: "1234567890",
             client_secret: "1234567890",
             id: 1234,
             scopes: ["read", "write", "follow"],
             redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
           } =
             Hunter.create_app(
               "hunter",
               "urn:ietf:wg:oauth:2.0:oob",
               ["read", "write", "follow"],
               nil,
               save?: false,
               api_base_url: "https://mastodon.example"
             )
  end

  test "verify_app_credentials/1 confirms the app token and decodes the app" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/apps/verify_credentials"
      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer app-tok"]

      respond_with(conn, %{
        name: "hunter",
        website: nil,
        scopes: ["read", "write"],
        redirect_uris: ["urn:ietf:wg:oauth:2.0:oob"]
      })
    end)

    conn = Hunter.new(base_url: "https://mastodon.example", access_token: "app-tok")

    assert %Hunter.Application{
             name: "hunter",
             client_secret: nil,
             scopes: ["read", "write"],
             redirect_uris: ["urn:ietf:wg:oauth:2.0:oob"]
           } = Hunter.verify_app_credentials(conn)
  end

  test "should allow to store credentials on home directory" do
    stub_request(fn conn ->
      assert conn.request_path == "/api/v1/apps"
      respond_with(conn, %{client_id: "1234567890", client_secret: "1234567890", id: 1234})
    end)

    home = Hunter.Config.home()
    tmp_dir = Path.expand("../../tmp", __DIR__)
    Application.put_env(:hunter, :home, tmp_dir)
    on_exit(fn -> Application.put_env(:hunter, :home, home) end)
    app_name = "hunter"

    assert %Hunter.Application{
             client_id: "1234567890",
             client_secret: "1234567890",
             id: 1234,
             scopes: ["read"]
           } =
             Hunter.create_app(
               app_name,
               "urn:ietf:wg:oauth:2.0:oob",
               ["read"],
               nil,
               save?: true,
               api_base_url: "https://mastodon.example"
             )

    assert %Hunter.Application{scopes: ["read"], redirect_uri: "urn:ietf:wg:oauth:2.0:oob"} =
             Hunter.load_credentials(app_name)
  end

  test "should allow to load persisted app's credentials" do
    home = Hunter.Config.home()
    tmp_dir = Path.expand("../../tmp", __DIR__)
    app_dir = Path.join(tmp_dir, "apps")
    app_name = "load"
    Application.put_env(:hunter, :home, tmp_dir)
    on_exit(fn -> Application.put_env(:hunter, :home, home) end)

    expected = %{
      id: 1234,
      client_secret: "1234567890",
      client_id: "1234567890",
      scopes: ["read", "write"],
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
    }

    unless File.exists?(app_dir), do: File.mkdir_p!(app_dir)

    File.write!("#{app_dir}/#{app_name}.json", Poison.encode!(expected))

    assert %Hunter.Application{
             scopes: ["read", "write"],
             redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
           } =
             app = Hunter.load_credentials(app_name)

    assert Map.take(Map.from_struct(app), Map.keys(expected)) == expected
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Validation failed"}, 422)
    end)

    assert_raise Hunter.Error, fn ->
      Hunter.create_app("hunter", "urn:ietf:wg:oauth:2.0:oob", ["read"], nil,
        api_base_url: "https://mastodon.example"
      )
    end
  end
end
