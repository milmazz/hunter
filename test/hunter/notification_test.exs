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

    assert Notification.clear_notifications(@conn) == true
  end

  test "dismiss a single notification" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/notifications/17476/dismiss"
      respond_with(conn, %{})
    end)

    assert Notification.clear_notification(@conn, 17_476) == true
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Notification.notification(@conn, 0) end
  end

  test "returns the unread count" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/notifications/unread_count"
      respond_with(conn, %{count: 7})
    end)

    assert Notification.unread_count(@conn) == 7
  end

  test "returns the notification filtering policy" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v2/notifications/policy"
      respond_with_fixture(conn, "notification_policy")
    end)

    assert %Hunter.NotificationPolicy{for_private_mentions: "filter"} =
             policy =
             Notification.notification_policy(@conn)

    assert policy.summary["pending_requests_count"] == 3
  end

  test "updates the notification filtering policy" do
    stub_request(fn conn ->
      assert conn.method == "PATCH"
      assert conn.request_path == "/api/v2/notifications/policy"
      assert %{"for_not_following" => "filter"} = read_json_body!(conn)
      respond_with_fixture(conn, "notification_policy")
    end)

    assert %Hunter.NotificationPolicy{} =
             Notification.update_notification_policy(@conn, for_not_following: "filter")
  end

  test "returns notification requests" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/notifications/requests"
      respond_with_fixture(conn, "notification_request", wrap: :list)
    end)

    assert [%Hunter.NotificationRequest{notifications_count: "5"} = request] =
             Notification.notification_requests(@conn)

    assert %Hunter.Account{username: "kadaba"} = request.account
  end

  test "returns a single notification request" do
    stub_request(fn conn ->
      assert conn.request_path == "/api/v1/notifications/requests/112456967201894256"
      respond_with_fixture(conn, "notification_request")
    end)

    assert %Hunter.NotificationRequest{id: "112456967201894256"} =
             Notification.notification_request(@conn, "112456967201894256")
  end

  test "accepts and dismisses a notification request" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/notifications/requests/112456967201894256/accept"
      respond_with(conn, %{})
    end)

    assert Notification.accept_notification_request(@conn, "112456967201894256") == true

    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/notifications/requests/112456967201894256/dismiss"
      respond_with(conn, %{})
    end)

    assert Notification.dismiss_notification_request(@conn, "112456967201894256") == true
  end

  test "accepts and dismisses notification requests in bulk" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/notifications/requests/accept"
      assert %{"id" => ["1", "2"]} = read_json_body!(conn)
      respond_with(conn, %{})
    end)

    assert Notification.accept_notification_requests(@conn, ["1", "2"]) == true

    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/notifications/requests/dismiss"
      assert %{"id" => ["3"]} = read_json_body!(conn)
      respond_with(conn, %{})
    end)

    assert Notification.dismiss_notification_requests(@conn, ["3"]) == true
  end

  test "checks whether accepted notification requests have been merged" do
    stub_request(fn conn ->
      assert conn.request_path == "/api/v1/notifications/requests/merged"
      respond_with(conn, %{merged: true})
    end)

    assert Notification.notification_requests_merged?(@conn) == true
  end

  test "returns grouped notifications" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v2/notifications"
      assert conn.query_string == "limit=10"
      respond_with_fixture(conn, "grouped_notifications")
    end)

    results = Notification.grouped_notifications(@conn, limit: 10)

    assert %Hunter.GroupedNotificationsResults{} = results
    assert [%Hunter.NotificationGroup{type: "favourite"}] = results.notification_groups
  end

  test "returns a single notification group" do
    stub_request(fn conn ->
      assert conn.request_path == "/api/v2/notifications/favourite-103270115826048975"
      respond_with_fixture(conn, "grouped_notifications")
    end)

    assert %Hunter.GroupedNotificationsResults{} =
             Notification.notification_group(@conn, "favourite-103270115826048975")
  end

  test "dismisses a notification group" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v2/notifications/favourite-103270115826048975/dismiss"
      respond_with(conn, %{})
    end)

    assert Notification.dismiss_notification_group(@conn, "favourite-103270115826048975") ==
             true
  end

  test "returns accounts of a notification group" do
    stub_request(fn conn ->
      assert conn.request_path ==
               "/api/v2/notifications/favourite-103270115826048975/accounts"

      respond_with_fixture(conn, "account", wrap: :list)
    end)

    assert [%Hunter.Account{username: "milmazz"}] =
             Notification.notification_group_accounts(@conn, "favourite-103270115826048975")
  end

  test "returns the grouped unread count" do
    stub_request(fn conn ->
      assert conn.request_path == "/api/v2/notifications/unread_count"
      respond_with(conn, %{count: 3})
    end)

    assert Notification.grouped_unread_count(@conn) == 3
  end
end
