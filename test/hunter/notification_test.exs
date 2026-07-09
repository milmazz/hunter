defmodule Hunter.NotificationTest do
  use Hunter.ReqCase, async: true

  alias Hunter.{Account, Notification}

  @conn Hunter.Client.new(base_url: "https://mastodon.example", access_token: "123456")

  test "fetch user's notifications with query params" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/notifications"
      assert conn.query_string == "limit=1"
      respond_with_fixture(conn, "notification", wrap: :list)
    end)

    [notification] = Notification.notifications(@conn, limit: 1)

    assert %Notification{type: "mention"} = notification
    assert %Account{username: "kadaba"} = notification.account
    assert %Hunter.Status{visibility: "public"} = notification.status
  end

  test "fetch a single notification" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/notifications/34975861"
      respond_with_fixture(conn, "notification")
    end)

    notification = Notification.notification(@conn, 34_975_861)

    assert %Notification{id: "34975861", type: "mention"} = notification
    assert "kadaba" == notification.account.username
  end

  test "deletes all notifications from Mastodon server" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/notifications/clear"
      respond_with(conn, %{})
    end)

    assert Notification.clear_notifications(@conn)
  end

  test "dismiss a single notification" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/notifications/17476/dismiss"
      respond_with(conn, %{})
    end)

    assert Notification.clear_notification(@conn, 17_476)
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Notification.notification(@conn, 0) end
  end
end
