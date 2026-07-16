defmodule Hunter.Integration.MastodonTest do
  use Hunter.IntegrationCase, async: false

  alias Hunter.{Account, Attachment, Instance, Relationship, Status}

  @png Base.decode64!(
         "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
       )

  test "verifies credentials of both provisioned users", %{conn: conn, conn2: conn2} do
    assert %Account{username: "hunter"} = Hunter.verify_credentials(conn)
    assert %Account{username: "kadaba"} = Hunter.verify_credentials(conn2)
  end

  test "fetches instance information", %{conn: conn} do
    assert %Instance{domain: domain, version: version} = Hunter.instance_info(conn)
    assert is_binary(domain)
    assert is_binary(version)
  end

  test "status lifecycle: create, fetch, favourite, reblog, destroy", %{
    conn: conn,
    conn2: conn2
  } do
    text = "hunter integration test #hunterci"

    status = Hunter.create_status(conn, text)
    assert %Status{id: id, content: content} = status
    on_exit(fn -> destroy_quietly(conn, id) end)
    assert content =~ "hunterci"

    assert %Status{id: ^id} = Hunter.status(conn, id)

    assert %Status{favourited: true} = Hunter.favourite(conn2, id)
    assert %Status{} = Hunter.unfavourite(conn2, id)

    assert %Status{reblogged: true} = Hunter.reblog(conn2, id)
    assert %Status{} = Hunter.unreblog(conn2, id)

    assert Hunter.destroy_status(conn, id)

    # deletion is synchronous; a subsequent fetch is a 404, which request! raises
    assert_raise Hunter.Error, fn -> Hunter.status(conn, id) end
  end

  test "statuses appear on the local public timeline", %{conn: conn} do
    %Status{id: id} = Hunter.create_status(conn, "timeline check #hunterci")
    on_exit(fn -> destroy_quietly(conn, id) end)

    eventually(fn ->
      timeline = Hunter.public_timeline(conn, local: true)
      assert Enum.any?(timeline, &(&1.id == id))
    end)

    Hunter.destroy_status(conn, id)
  end

  test "follow, relationship, and notifications across accounts", %{conn: conn, conn2: conn2} do
    %Account{username: "hunter"} = Hunter.verify_credentials(conn)
    %Account{id: id2} = Hunter.verify_credentials(conn2)

    assert %Relationship{following: true} = Hunter.follow(conn, id2)
    on_exit(fn -> unfollow_quietly(conn, id2) end)
    assert [%Relationship{following: true}] = Hunter.relationships(conn, [id2])

    %Status{id: status_id} = Hunter.create_status(conn2, "hello @hunter #hunterci")
    on_exit(fn -> destroy_quietly(conn2, status_id) end)

    notification =
      eventually(fn ->
        notifications = Hunter.notifications(conn)

        case Enum.find(notifications, fn n ->
               n.type == "mention" and n.account.username == "kadaba"
             end) do
          nil -> raise "mention notification not delivered yet"
          notification -> notification
        end
      end)

    assert Hunter.clear_notification(conn, notification.id)
    refute Enum.any?(Hunter.notifications(conn), &(&1.id == notification.id))

    assert %Relationship{following: false} = Hunter.unfollow(conn, id2)
    Hunter.destroy_status(conn2, status_id)
  end

  test "follow requests against a locked account", %{conn: conn, conn2: conn2} do
    %Account{id: id1} = Hunter.verify_credentials(conn)
    %Account{id: id2} = Hunter.verify_credentials(conn2)

    assert %Account{locked: true} = Hunter.update_credentials(conn2, %{locked: true})
    on_exit(fn -> unlock_quietly(conn2) end)

    assert %Relationship{requested: true, following: false} = Hunter.follow(conn, id2)
    on_exit(fn -> unfollow_quietly(conn, id2) end)

    requesters = Hunter.follow_requests(conn2)
    assert Enum.any?(requesters, &(&1.id == id1))

    assert %Relationship{followed_by: true} = Hunter.accept_follow_request(conn2, id1)

    assert %Account{locked: false} = Hunter.update_credentials(conn2, %{locked: false})
    Hunter.unfollow(conn, id2)
  end

  test "searches for accounts", %{conn: conn} do
    accounts = Hunter.search_account(conn, q: "kadaba")

    assert Enum.any?(accounts, &(&1.username == "kadaba"))
  end

  @tag :tmp_dir
  test "uploads media and attaches it to a status", %{conn: conn, tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "hunter-integration.png")
    File.write!(path, @png)

    assert %Attachment{id: media_id, type: "image"} = Hunter.upload_media(conn, path)

    %Status{id: id, media_attachments: attachments} =
      eventually(fn ->
        Hunter.create_status(conn, "media test #hunterci", media_ids: [media_id])
      end)

    on_exit(fn -> destroy_quietly(conn, id) end)
    assert Enum.any?(attachments, &(&1.id == media_id))
    Hunter.destroy_status(conn, id)
  end

  test "edits a status and inspects its source and history", %{conn: conn} do
    %Status{id: id} = Hunter.create_status(conn, "first draft #hunterci")
    on_exit(fn -> destroy_quietly(conn, id) end)

    assert %Status{content: content, edited_at: edited_at} =
             Hunter.edit_status(conn, id, "final version #hunterci")

    assert content =~ "final version"
    assert is_binary(edited_at)

    assert %Hunter.StatusSource{id: ^id, text: "final version #hunterci"} =
             Hunter.status_source(conn, id)

    history = Hunter.status_history(conn, id)
    assert length(history) == 2
    assert [%Hunter.StatusEdit{content: first} | _] = history
    assert first =~ "first draft"

    Hunter.destroy_status(conn, id)
  end

  test "bookmarks, pins, and mutes a conversation", %{conn: conn} do
    %Status{id: id} = Hunter.create_status(conn, "interactions probe #hunterci")
    on_exit(fn -> destroy_quietly(conn, id) end)

    assert %Status{bookmarked: true} = Hunter.bookmark(conn, id)
    assert Enum.any?(Hunter.bookmarks(conn), &(&1.id == id))
    assert %Status{bookmarked: false} = Hunter.unbookmark(conn, id)
    refute Enum.any?(Hunter.bookmarks(conn), &(&1.id == id))

    assert %Status{pinned: true} = Hunter.pin(conn, id)
    assert %Status{pinned: false} = Hunter.unpin(conn, id)

    assert %Status{muted: true} = Hunter.mute_conversation(conn, id)
    assert %Status{muted: false} = Hunter.unmute_conversation(conn, id)

    Hunter.destroy_status(conn, id)
  end

  test "poll lifecycle: create, fetch, and vote across accounts", %{conn: conn, conn2: conn2} do
    status =
      Hunter.create_status(conn, "poll probe #hunterci",
        poll: %{options: ["yes", "no"], expires_in: 3600}
      )

    assert %Status{id: id, poll: %Hunter.Poll{id: poll_id, expired: false}} = status
    on_exit(fn -> destroy_quietly(conn, id) end)

    assert %Hunter.Poll{multiple: false, votes_count: 0} = Hunter.poll(conn2, poll_id)

    assert %Hunter.Poll{voted: true, own_votes: [0], votes_count: 1} =
             Hunter.vote(conn2, poll_id, [0])

    Hunter.destroy_status(conn, id)
  end

  test "fetches multiple statuses by id", %{conn: conn} do
    %Status{id: id1} = Hunter.create_status(conn, "batch one #hunterci")
    %Status{id: id2} = Hunter.create_status(conn, "batch two #hunterci")
    on_exit(fn -> destroy_quietly(conn, id1) end)
    on_exit(fn -> destroy_quietly(conn, id2) end)

    fetched = Hunter.statuses_by_ids(conn, [id1, id2])
    assert Enum.map(fetched, & &1.id) |> Enum.sort() == Enum.sort([id1, id2])

    Hunter.destroy_status(conn, id1)
    Hunter.destroy_status(conn, id2)
  end

  test "scheduling a status returns a scheduled status; idempotency key deduplicates", %{
    conn: conn
  } do
    scheduled_at =
      DateTime.utc_now() |> DateTime.add(600, :second) |> DateTime.to_iso8601()

    assert %Hunter.ScheduledStatus{id: _, scheduled_at: _, params: %{"text" => text}} =
             Hunter.create_status(conn, "scheduled probe #hunterci", scheduled_at: scheduled_at)

    assert text =~ "scheduled probe"

    key = "hunter-ci-#{System.unique_integer([:positive])}"

    %Status{id: id} =
      Hunter.create_status(conn, "idempotent probe #hunterci", idempotency_key: key)

    on_exit(fn -> destroy_quietly(conn, id) end)

    assert %Status{id: ^id} =
             Hunter.create_status(conn, "idempotent probe #hunterci", idempotency_key: key)

    Hunter.destroy_status(conn, id)
  end

  @tag :tmp_dir
  test "updates media metadata before attaching", %{conn: conn, tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "hunter-media-update.png")
    File.write!(path, @png)

    assert %Attachment{id: media_id} = Hunter.upload_media(conn, path)

    assert %Attachment{description: "a tiny test pixel"} =
             Hunter.update_media(conn, media_id, description: "a tiny test pixel")

    assert %Attachment{id: ^media_id, description: "a tiny test pixel"} =
             Hunter.media_attachment(conn, media_id)
  end

  test "list lifecycle: create, membership, timeline, update, destroy", %{
    conn: conn,
    conn2: conn2
  } do
    %Account{id: id2} = Hunter.verify_credentials(conn2)

    # membership requires following the account first
    assert %Relationship{following: true} = Hunter.follow(conn, id2)
    on_exit(fn -> unfollow_quietly(conn, id2) end)

    assert %Hunter.List{id: list_id, title: "hunter ci"} =
             Hunter.create_list(conn, "hunter ci", replies_policy: "followed")

    on_exit(fn -> destroy_list_quietly(conn, list_id) end)

    assert Hunter.add_accounts_to_list(conn, list_id, [id2])
    assert [%Account{id: ^id2}] = Hunter.list_accounts(conn, list_id)
    assert Enum.any?(Hunter.account_lists(conn, id2), &(&1.id == list_id))
    assert Enum.any?(Hunter.lists(conn), &(&1.id == list_id))

    %Status{id: status_id} = Hunter.create_status(conn2, "list timeline probe #hunterci")
    on_exit(fn -> destroy_quietly(conn2, status_id) end)

    eventually(fn ->
      timeline = Hunter.list_timeline(conn, list_id)
      assert Enum.any?(timeline, &(&1.id == status_id))
    end)

    assert %Hunter.List{title: "hunter ci renamed"} =
             Hunter.update_list(conn, list_id, title: "hunter ci renamed")

    assert Hunter.remove_accounts_from_list(conn, list_id, [id2])
    assert [] = Hunter.list_accounts(conn, list_id)

    assert Hunter.destroy_list(conn, list_id)
    assert_raise Hunter.Error, fn -> Hunter.list(conn, list_id) end

    Hunter.destroy_status(conn2, status_id)
    Hunter.unfollow(conn, id2)
  end

  test "notification policy roundtrip and unread counts", %{conn: conn} do
    policy = Hunter.notification_policy(conn)
    assert %Hunter.NotificationPolicy{} = policy
    original = policy.for_not_following

    assert %Hunter.NotificationPolicy{for_not_following: "filter"} =
             Hunter.update_notification_policy(conn, for_not_following: "filter")

    on_exit(fn ->
      Hunter.update_notification_policy(conn, for_not_following: original)
    end)

    assert %Hunter.NotificationPolicy{for_not_following: ^original} =
             Hunter.update_notification_policy(conn, for_not_following: original)

    assert is_integer(Hunter.unread_count(conn))
    assert is_integer(Hunter.grouped_unread_count(conn))
  end

  test "filtered notifications become requests that can be accepted", %{
    conn: conn,
    conn2: conn2
  } do
    # accepting a request grants the sender a permanent NotificationPermission,
    # so a previous run against a reused database would leave kadaba's mentions
    # unfiltered; block/unblock is the only API-visible way to revoke it
    %Account{id: id2} = Hunter.verify_credentials(conn2)
    reset_notification_permission(conn, id2)
    on_exit(fn -> reset_notification_permission(conn, id2) end)

    # filter notifications from accounts the user does not follow, then have
    # the (unfollowed) second account mention them
    original = Hunter.notification_policy(conn).for_not_following

    Hunter.update_notification_policy(conn, for_not_following: "filter")
    on_exit(fn -> Hunter.update_notification_policy(conn, for_not_following: original) end)

    %Status{id: status_id} = Hunter.create_status(conn2, "filtered mention @hunter #hunterci")
    on_exit(fn -> destroy_quietly(conn2, status_id) end)

    request =
      eventually(fn ->
        case Enum.find(Hunter.notification_requests(conn), fn request ->
               request.account.username == "kadaba"
             end) do
          nil -> raise "notification request not created yet"
          request -> request
        end
      end)

    assert %Hunter.NotificationRequest{} = request

    assert %Hunter.NotificationRequest{id: _} =
             Hunter.notification_request(conn, request.id)

    assert Hunter.accept_notification_request(conn, request.id)
    eventually(fn -> assert Hunter.notification_requests_merged?(conn) end)

    Hunter.update_notification_policy(conn, for_not_following: original)
    Hunter.destroy_status(conn2, status_id)
  end

  test "grouped notifications reference accounts and statuses", %{conn: conn, conn2: conn2} do
    # favourites are groupable (mentions are not: their synthesized
    # ungrouped-* keys match nothing on the group endpoints)
    %Status{id: status_id} = Hunter.create_status(conn, "groupable probe #hunterci")
    on_exit(fn -> destroy_quietly(conn, status_id) end)

    assert %Status{} = Hunter.favourite(conn2, status_id)

    group =
      eventually(fn ->
        results = Hunter.grouped_notifications(conn, types: ["favourite"])
        assert %Hunter.GroupedNotificationsResults{} = results

        case Enum.find(results.notification_groups, fn group ->
               group.type == "favourite" and group.status_id == status_id
             end) do
          nil -> raise "notification group not delivered yet"
          group -> group
        end
      end)

    assert %Hunter.GroupedNotificationsResults{notification_groups: [_ | _]} =
             Hunter.notification_group(conn, group.group_key)

    accounts = Hunter.notification_group_accounts(conn, group.group_key)
    assert Enum.any?(accounts, &(&1.username == "kadaba"))

    assert Hunter.dismiss_notification_group(conn, group.group_key)

    Hunter.destroy_status(conn, status_id)
  end

  test "web push subscription lifecycle", %{conn: conn} do
    subscription = %{
      endpoint: "https://push.example.com/listener",
      keys: %{
        p256dh:
          "BCk-QqERU0q-CfYZjcuB6lnyyOYfJ2AifKqfeGIm7Z-HiTU5T9eTG5GxVA0_OH5mMlI4UkkDTpaZwozy0TzdZ2M=",
        auth: "tBHItJI5svbpez7KI4CCXg=="
      }
    }

    created =
      Hunter.create_push_subscription(conn, subscription, %{
        alerts: %{mention: true}
      })

    assert %Hunter.WebPushSubscription{endpoint: "https://push.example.com/listener"} = created
    on_exit(fn -> delete_push_quietly(conn) end)

    fetched = Hunter.push_subscription(conn)
    assert fetched.id == created.id
    assert fetched.alerts["mention"] == true

    updated =
      Hunter.update_push_subscription(conn, %{
        alerts: %{mention: true, reblog: true}
      })

    assert updated.alerts["reblog"] == true

    assert Hunter.delete_push_subscription(conn)
    assert_raise Hunter.Error, fn -> Hunter.push_subscription(conn) end
  end

  test "query parameters take effect server-side", %{conn: conn} do
    %Account{id: account_id} = Hunter.verify_credentials(conn)

    %Status{id: id1} = Hunter.create_status(conn, "pagination one #hunterci")
    %Status{id: id2} = Hunter.create_status(conn, "pagination two #hunterci")
    on_exit(fn -> destroy_quietly(conn, id1) end)
    on_exit(fn -> destroy_quietly(conn, id2) end)

    eventually(fn ->
      assert [%Status{}] = Hunter.statuses(conn, account_id, limit: 1)
    end)

    older = Hunter.statuses(conn, account_id, max_id: id2)
    refute Enum.any?(older, &(&1.id == id2))
    assert Enum.any?(older, &(&1.id == id1))

    Hunter.destroy_status(conn, id1)
    Hunter.destroy_status(conn, id2)
  end

  test "searches via /api/v2/search returning v2 shapes", %{conn: conn} do
    %Status{id: id} = Hunter.create_status(conn, "tagged search probe #hunterci")
    on_exit(fn -> destroy_quietly(conn, id) end)

    eventually(fn ->
      result = Hunter.search(conn, "hunterci")
      assert Enum.any?(result.hashtags, &match?(%Hunter.Tag{name: "hunterci"}, &1))
    end)

    people = Hunter.search(conn, "kadaba")
    assert Enum.any?(people.accounts, &(&1.username == "kadaba"))

    Hunter.destroy_status(conn, id)
  end

  test "app credentials flow: create_app + log_in_app + verify_app_credentials", %{conn: conn} do
    app_name = "hunter-auth-#{System.unique_integer([:positive])}"

    app =
      Hunter.create_app(app_name, "urn:ietf:wg:oauth:2.0:oob", ["read", "write"], nil,
        api_base_url: conn.base_url
      )

    assert %Hunter.Application{scopes: ["read", "write"]} = app

    app_conn = Hunter.log_in_app(app, conn.base_url)
    assert %Hunter.Client{access_token: token} = app_conn
    assert is_binary(token)

    assert %Hunter.Application{name: ^app_name} = Hunter.verify_app_credentials(app_conn)
  end

  test "revoked app tokens stop working", %{conn: conn} do
    app =
      Hunter.create_app(
        "hunter-revoke-#{System.unique_integer([:positive])}",
        "urn:ietf:wg:oauth:2.0:oob",
        ["read"],
        nil,
        api_base_url: conn.base_url
      )

    app_conn = Hunter.log_in_app(app, conn.base_url)
    assert %Hunter.Application{} = Hunter.verify_app_credentials(app_conn)

    assert Hunter.revoke_token(app, app_conn.access_token, conn.base_url) == true

    assert_raise Hunter.Error, fn ->
      Hunter.verify_app_credentials(app_conn)
    end
  end

  test "blocks and unblocks a domain", %{conn: conn} do
    assert Hunter.block_domain(conn, "blocked.example")
    on_exit(fn -> unblock_quietly(conn, "blocked.example") end)
    assert "blocked.example" in Hunter.blocked_domains(conn)

    assert Hunter.unblock_domain(conn, "blocked.example")
    refute "blocked.example" in Hunter.blocked_domains(conn)
  end

  test "OAuth authorization-code flow: log_in_oauth yields a working client", %{
    conn: conn,
    oauth_client_id: client_id,
    oauth_client_secret: client_secret,
    oauth_code: code
  } do
    app = %Hunter.Application{
      client_id: client_id,
      client_secret: client_secret,
      scopes: ["read", "write"],
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
    }

    logged_in = Hunter.log_in_oauth(app, code, conn.base_url)
    assert %Hunter.Client{access_token: token} = logged_in
    assert is_binary(token)

    %Status{id: id} = Hunter.create_status(logged_in, "oauth flow works #hunterci")
    on_exit(fn -> destroy_quietly(logged_in, id) end)
    Hunter.destroy_status(logged_in, id)
  end

  test "PKCE authorization-code flow: verifier round-trips", %{
    conn: conn,
    oauth_client_id: client_id,
    oauth_client_secret: client_secret,
    pkce_code: code,
    pkce_verifier: verifier
  } do
    app = %Hunter.Application{
      client_id: client_id,
      client_secret: client_secret,
      scopes: ["read", "write"],
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
    }

    logged_in = Hunter.log_in_oauth(app, code, conn.base_url, code_verifier: verifier)
    assert %Hunter.Client{access_token: token} = logged_in
    assert is_binary(token)

    %Status{id: id} = Hunter.create_status(logged_in, "pkce flow works #hunterci")
    on_exit(fn -> destroy_quietly(logged_in, id) end)
    Hunter.destroy_status(logged_in, id)
  end

  test "oauth_server_metadata returns RFC 8414 metadata", %{conn: conn} do
    metadata = Hunter.oauth_server_metadata(conn.base_url)

    assert is_map(metadata)
    assert is_binary(metadata["issuer"])
    assert "S256" in metadata["code_challenge_methods_supported"]
  end

  test "userinfo returns OIDC claims for the token's user", %{conn: conn} do
    claims = Hunter.userinfo(conn)

    assert is_binary(claims["sub"])
    assert claims["preferred_username"] == "hunter"
  end

  # Failure-path cleanup: on_exit nets that tolerate state already removed by
  # the test body's own assertions.
  defp destroy_quietly(conn, id) do
    Hunter.destroy_status(conn, id)
    :ok
  rescue
    Hunter.Error -> :ok
  end

  defp unfollow_quietly(conn, id) do
    Hunter.unfollow(conn, id)
    :ok
  rescue
    Hunter.Error -> :ok
  end

  defp delete_push_quietly(conn) do
    Hunter.delete_push_subscription(conn)
    :ok
  rescue
    Hunter.Error -> :ok
  end

  defp destroy_list_quietly(conn, id) do
    Hunter.destroy_list(conn, id)
    :ok
  rescue
    Hunter.Error -> :ok
  end

  defp unblock_quietly(conn, domain) do
    Hunter.unblock_domain(conn, domain)
    :ok
  rescue
    Hunter.Error -> :ok
  end

  defp unlock_quietly(conn) do
    Hunter.update_credentials(conn, %{locked: false})
    :ok
  rescue
    Hunter.Error -> :ok
  end

  # Mastodon's BlockService destroys any NotificationPermission granted to the
  # blocked account, so a block/unblock pair resets notification filtering for
  # that sender. The unblock runs even if the block fails.
  defp reset_notification_permission(conn, id) do
    try do
      Hunter.block(conn, id)
    rescue
      Hunter.Error -> :ok
    end

    Hunter.unblock(conn, id)
    :ok
  rescue
    Hunter.Error -> :ok
  end

  describe "streaming" do
    test "health check and live user-stream update", %{conn: conn} do
      assert Hunter.Streaming.health?(conn)

      {:ok, pid} =
        Hunter.Streaming.connect(conn,
          streams: ["user"],
          transport_opts: [verify: :verify_none]
        )

      status = Hunter.create_status(conn, "streaming test #{System.unique_integer([:positive])}")

      try do
        status_id = status.id

        assert_receive {:hunter_stream, ^pid,
                        %Hunter.Streaming.Event{
                          type: "update",
                          payload: %Hunter.Status{id: ^status_id}
                        }},
                       30_000

        Hunter.Streaming.close(pid)
        assert_receive {:hunter_stream, ^pid, {:closed, :local}}, 5_000
      after
        Hunter.destroy_status(conn, status.id)
      end
    end
  end
end
