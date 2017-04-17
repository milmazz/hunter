defmodule Hunter.NotificationTest do
  use ExUnit.Case, async: true

  alias Hunter.Notification

  setup do
    [conn: Hunter.Client.new([base_url: "https://example.com", bearer_token: "123456"])]
  end

  test "fetch user's notifications", %{conn: conn} do
    notifications = conn |> Notification.notifications() |> List.first()
    assert "paperswelove" == notifications.account["username"]
    assert "follow" == notifications.type
  end

  test "fetch a single notification", %{conn: conn} do
    notification = Notification.notification(conn, 17_476)
    assert "paperswelove" == notification.account["username"]
    assert "follow" == notification.type
  end
end
