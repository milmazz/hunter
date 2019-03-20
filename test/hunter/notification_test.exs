defmodule Hunter.NotificationTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.{Account, Notification}

  @conn Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")

  setup :verify_on_exit!

  test "fetch user's notifications" do
    expect(Hunter.ApiMock, :notifications, fn _conn, _opts ->
      [%Notification{account: %Account{username: "paperswelove"}, type: "follow"}]
    end)

    [notification | _] = Notification.notifications(@conn)
    assert "paperswelove" == notification.account.username
    assert "follow" == notification.type
  end

  test "fetch a single notification" do
    expect(Hunter.ApiMock, :notification, fn _conn, _id ->
      %Notification{account: %Account{username: "paperswelove"}, type: "follow"}
    end)

    notification = Notification.notification(@conn, 17_476)
    assert "paperswelove" == notification.account.username
    assert "follow" == notification.type
  end
end
