defmodule Hunter.WebPushSubscriptionTest do
  use Hunter.ReqCase, async: true

  alias Hunter.WebPushSubscription

  @conn Hunter.new(base_url: "https://mastodon.example", access_token: "123456")

  @subscription %{
    endpoint: "https://yourdomain.example/listener",
    keys: %{
      p256dh:
        "BCk-QqERU0q-CfYZjcuB6lnyyOYfJ2AifKqfeGIm7Z-HiTU5T9eTG5GxVA0_OH5mMlI4UkkDTpaZwozy0TzdZ2M=",
      auth: "tBHItJI5svbpez7KI4CCXg=="
    },
    standard: true
  }

  test "creates a push subscription" do
    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v1/push/subscription"

      body = read_json_body!(conn)
      assert body["subscription"]["endpoint"] == "https://yourdomain.example/listener"
      assert body["subscription"]["keys"]["auth"] == "tBHItJI5svbpez7KI4CCXg=="
      assert body["data"]["alerts"]["mention"] == true

      respond_with_fixture(conn, "web_push_subscription")
    end)

    assert %WebPushSubscription{id: "328183", standard: true} =
             Hunter.create_push_subscription(@conn, @subscription, %{
               alerts: %{mention: true}
             })
  end

  test "returns the current push subscription" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/push/subscription"
      respond_with_fixture(conn, "web_push_subscription")
    end)

    subscription = Hunter.push_subscription(@conn)

    assert %WebPushSubscription{endpoint: "https://yourdomain.example/listener"} = subscription
    assert subscription.alerts["mention"] == true
  end

  test "updates the push subscription alerts" do
    stub_request(fn conn ->
      assert conn.method == "PUT"
      assert conn.request_path == "/api/v1/push/subscription"
      assert %{"data" => %{"alerts" => %{"reblog" => true}}} = read_json_body!(conn)
      respond_with_fixture(conn, "web_push_subscription")
    end)

    assert %WebPushSubscription{} =
             Hunter.update_push_subscription(@conn, %{alerts: %{reblog: true}})
  end

  test "deletes the push subscription" do
    stub_request(fn conn ->
      assert conn.method == "DELETE"
      assert conn.request_path == "/api/v1/push/subscription"
      respond_with(conn, %{})
    end)

    assert Hunter.delete_push_subscription(@conn) == true
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Hunter.push_subscription(@conn) end
  end
end
