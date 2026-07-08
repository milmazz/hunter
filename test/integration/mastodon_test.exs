defmodule Hunter.Integration.MastodonTest do
  use Hunter.IntegrationCase, async: false

  alias Hunter.{Account, Attachment, Domain, Instance, Notification, Relationship, Result, Status}

  @png Base.decode64!(
         "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
       )

  test "verifies credentials of both provisioned users", %{conn: conn, conn2: conn2} do
    assert %Account{username: "hunter"} = Account.verify_credentials(conn)
    assert %Account{username: "kadaba"} = Account.verify_credentials(conn2)
  end

  test "fetches instance information", %{conn: conn} do
    assert %Instance{domain: domain, version: version} = Instance.instance_info(conn)
    assert is_binary(domain)
    assert is_binary(version)
  end

  test "status lifecycle: create, fetch, favourite, reblog, destroy", %{
    conn: conn,
    conn2: conn2
  } do
    text = "hunter integration test #hunterci"

    status = Status.create_status(conn, text)
    assert %Status{id: id, content: content} = status
    on_exit(fn -> destroy_quietly(conn, id) end)
    assert content =~ "hunterci"

    assert %Status{id: ^id} = Status.status(conn, id)

    assert %Status{favourited: true} = Status.favourite(conn2, id)
    assert %Status{} = Status.unfavourite(conn2, id)

    assert %Status{reblogged: true} = Status.reblog(conn2, id)
    assert %Status{} = Status.unreblog(conn2, id)

    assert Status.destroy_status(conn, id)

    # deletion is synchronous; a subsequent fetch is a 404, which request! raises
    assert_raise Hunter.Error, fn -> Status.status(conn, id) end
  end

  test "statuses appear on the local public timeline", %{conn: conn} do
    %Status{id: id} = Status.create_status(conn, "timeline check #hunterci")
    on_exit(fn -> destroy_quietly(conn, id) end)

    eventually(fn ->
      timeline = Status.public_timeline(conn, local: true)
      assert Enum.any?(timeline, &(&1.id == id))
    end)

    Status.destroy_status(conn, id)
  end

  test "follow, relationship, and notifications across accounts", %{conn: conn, conn2: conn2} do
    %Account{username: "hunter"} = Account.verify_credentials(conn)
    %Account{id: id2} = Account.verify_credentials(conn2)

    assert %Relationship{following: true} = Relationship.follow(conn, id2)
    on_exit(fn -> unfollow_quietly(conn, id2) end)
    assert [%Relationship{following: true}] = Relationship.relationships(conn, [id2])

    %Status{id: status_id} = Status.create_status(conn2, "hello @hunter #hunterci")
    on_exit(fn -> destroy_quietly(conn2, status_id) end)

    notification =
      eventually(fn ->
        notifications = Notification.notifications(conn)

        case Enum.find(notifications, fn n ->
               n.type == "mention" and n.account.username == "kadaba"
             end) do
          nil -> raise "mention notification not delivered yet"
          notification -> notification
        end
      end)

    assert Notification.clear_notification(conn, notification.id)
    refute Enum.any?(Notification.notifications(conn), &(&1.id == notification.id))

    assert %Relationship{following: false} = Relationship.unfollow(conn, id2)
    Status.destroy_status(conn2, status_id)
  end

  test "follow requests against a locked account", %{conn: conn, conn2: conn2} do
    %Account{id: id1} = Account.verify_credentials(conn)
    %Account{id: id2} = Account.verify_credentials(conn2)

    assert %Account{locked: true} = Account.update_credentials(conn2, %{locked: true})
    on_exit(fn -> unlock_quietly(conn2) end)

    assert %Relationship{requested: true, following: false} = Relationship.follow(conn, id2)
    on_exit(fn -> unfollow_quietly(conn, id2) end)

    requesters = Account.follow_requests(conn2)
    assert Enum.any?(requesters, &(&1.id == id1))

    assert %Relationship{followed_by: true} = Account.accept_follow_request(conn2, id1)

    assert %Account{locked: false} = Account.update_credentials(conn2, %{locked: false})
    Relationship.unfollow(conn, id2)
  end

  test "searches for accounts", %{conn: conn} do
    accounts = Account.search_account(conn, q: "kadaba")

    assert Enum.any?(accounts, &(&1.username == "kadaba"))
  end

  @tag :tmp_dir
  test "uploads media and attaches it to a status", %{conn: conn, tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "hunter-integration.png")
    File.write!(path, @png)

    assert %Attachment{id: media_id, type: "image"} = Attachment.upload_media(conn, path)

    %Status{id: id, media_attachments: attachments} =
      eventually(fn ->
        Status.create_status(conn, "media test #hunterci", media_ids: [media_id])
      end)

    on_exit(fn -> destroy_quietly(conn, id) end)
    assert Enum.any?(attachments, &(&1.id == media_id))
    Status.destroy_status(conn, id)
  end

  test "edits a status and inspects its source and history", %{conn: conn} do
    %Status{id: id} = Status.create_status(conn, "first draft #hunterci")
    on_exit(fn -> destroy_quietly(conn, id) end)

    assert %Status{content: content, edited_at: edited_at} =
             Status.edit_status(conn, id, "final version #hunterci")

    assert content =~ "final version"
    assert is_binary(edited_at)

    assert %Hunter.StatusSource{id: ^id, text: "final version #hunterci"} =
             Status.status_source(conn, id)

    history = Status.status_history(conn, id)
    assert length(history) == 2
    assert [%Hunter.StatusEdit{content: first} | _] = history
    assert first =~ "first draft"

    Status.destroy_status(conn, id)
  end

  test "bookmarks, pins, and mutes a conversation", %{conn: conn} do
    %Status{id: id} = Status.create_status(conn, "interactions probe #hunterci")
    on_exit(fn -> destroy_quietly(conn, id) end)

    assert %Status{bookmarked: true} = Status.bookmark(conn, id)
    assert Enum.any?(Status.bookmarks(conn), &(&1.id == id))
    assert %Status{bookmarked: false} = Status.unbookmark(conn, id)
    refute Enum.any?(Status.bookmarks(conn), &(&1.id == id))

    assert %Status{pinned: true} = Status.pin(conn, id)
    assert %Status{pinned: false} = Status.unpin(conn, id)

    assert %Status{muted: true} = Status.mute_conversation(conn, id)
    assert %Status{muted: false} = Status.unmute_conversation(conn, id)

    Status.destroy_status(conn, id)
  end

  test "poll lifecycle: create, fetch, and vote across accounts", %{conn: conn, conn2: conn2} do
    status =
      Status.create_status(conn, "poll probe #hunterci",
        poll: %{options: ["yes", "no"], expires_in: 3600}
      )

    assert %Status{id: id, poll: %Hunter.Poll{id: poll_id, expired: false}} = status
    on_exit(fn -> destroy_quietly(conn, id) end)

    assert %Hunter.Poll{multiple: false, votes_count: 0} = Hunter.Poll.poll(conn2, poll_id)

    assert %Hunter.Poll{voted: true, own_votes: [0], votes_count: 1} =
             Hunter.Poll.vote(conn2, poll_id, [0])

    Status.destroy_status(conn, id)
  end

  test "fetches multiple statuses by id", %{conn: conn} do
    %Status{id: id1} = Status.create_status(conn, "batch one #hunterci")
    %Status{id: id2} = Status.create_status(conn, "batch two #hunterci")
    on_exit(fn -> destroy_quietly(conn, id1) end)
    on_exit(fn -> destroy_quietly(conn, id2) end)

    fetched = Status.statuses_by_ids(conn, [id1, id2])
    assert Enum.map(fetched, & &1.id) |> Enum.sort() == Enum.sort([id1, id2])

    Status.destroy_status(conn, id1)
    Status.destroy_status(conn, id2)
  end

  test "scheduling a status returns a scheduled status; idempotency key deduplicates", %{
    conn: conn
  } do
    scheduled_at =
      DateTime.utc_now() |> DateTime.add(600, :second) |> DateTime.to_iso8601()

    assert %Hunter.ScheduledStatus{id: _, scheduled_at: _, params: %{"text" => text}} =
             Status.create_status(conn, "scheduled probe #hunterci", scheduled_at: scheduled_at)

    assert text =~ "scheduled probe"

    key = "hunter-ci-#{System.unique_integer([:positive])}"

    %Status{id: id} =
      Status.create_status(conn, "idempotent probe #hunterci", idempotency_key: key)

    on_exit(fn -> destroy_quietly(conn, id) end)

    assert %Status{id: ^id} =
             Status.create_status(conn, "idempotent probe #hunterci", idempotency_key: key)

    Status.destroy_status(conn, id)
  end

  @tag :tmp_dir
  test "updates media metadata before attaching", %{conn: conn, tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "hunter-media-update.png")
    File.write!(path, @png)

    assert %Attachment{id: media_id} = Attachment.upload_media(conn, path)

    assert %Attachment{description: "a tiny test pixel"} =
             Attachment.update_media(conn, media_id, description: "a tiny test pixel")

    assert %Attachment{id: ^media_id, description: "a tiny test pixel"} =
             Attachment.media_attachment(conn, media_id)
  end

  test "list lifecycle: create, membership, timeline, update, destroy", %{
    conn: conn,
    conn2: conn2
  } do
    %Account{id: id2} = Account.verify_credentials(conn2)

    # membership requires following the account first
    assert %Relationship{following: true} = Relationship.follow(conn, id2)
    on_exit(fn -> unfollow_quietly(conn, id2) end)

    assert %Hunter.List{id: list_id, title: "hunter ci"} =
             Hunter.List.create_list(conn, "hunter ci", replies_policy: "followed")

    on_exit(fn -> destroy_list_quietly(conn, list_id) end)

    assert Hunter.List.add_accounts_to_list(conn, list_id, [id2])
    assert [%Account{id: ^id2}] = Hunter.List.list_accounts(conn, list_id)
    assert Enum.any?(Hunter.List.account_lists(conn, id2), &(&1.id == list_id))
    assert Enum.any?(Hunter.List.lists(conn), &(&1.id == list_id))

    %Status{id: status_id} = Status.create_status(conn2, "list timeline probe #hunterci")
    on_exit(fn -> destroy_quietly(conn2, status_id) end)

    eventually(fn ->
      timeline = Status.list_timeline(conn, list_id)
      assert Enum.any?(timeline, &(&1.id == status_id))
    end)

    assert %Hunter.List{title: "hunter ci renamed"} =
             Hunter.List.update_list(conn, list_id, title: "hunter ci renamed")

    assert Hunter.List.remove_accounts_from_list(conn, list_id, [id2])
    assert [] = Hunter.List.list_accounts(conn, list_id)

    assert Hunter.List.destroy_list(conn, list_id)
    assert_raise Hunter.Error, fn -> Hunter.List.list(conn, list_id) end

    Status.destroy_status(conn2, status_id)
    Relationship.unfollow(conn, id2)
  end

  test "query parameters take effect server-side", %{conn: conn} do
    %Account{id: account_id} = Account.verify_credentials(conn)

    %Status{id: id1} = Status.create_status(conn, "pagination one #hunterci")
    %Status{id: id2} = Status.create_status(conn, "pagination two #hunterci")
    on_exit(fn -> destroy_quietly(conn, id1) end)
    on_exit(fn -> destroy_quietly(conn, id2) end)

    eventually(fn ->
      assert [%Status{}] = Status.statuses(conn, account_id, limit: 1)
    end)

    older = Status.statuses(conn, account_id, max_id: id2)
    refute Enum.any?(older, &(&1.id == id2))
    assert Enum.any?(older, &(&1.id == id1))

    Status.destroy_status(conn, id1)
    Status.destroy_status(conn, id2)
  end

  test "searches via /api/v2/search returning v2 shapes", %{conn: conn} do
    %Status{id: id} = Status.create_status(conn, "tagged search probe #hunterci")
    on_exit(fn -> destroy_quietly(conn, id) end)

    eventually(fn ->
      result = Result.search(conn, "hunterci")
      assert Enum.any?(result.hashtags, &match?(%Hunter.Tag{name: "hunterci"}, &1))
    end)

    people = Result.search(conn, "kadaba")
    assert Enum.any?(people.accounts, &(&1.username == "kadaba"))

    Status.destroy_status(conn, id)
  end

  test "README auth flow: create_app + log_in yields a token that can write", %{
    conn: conn,
    password2: password2
  } do
    app =
      Hunter.create_app(
        "hunter-auth-#{System.unique_integer([:positive])}",
        "urn:ietf:wg:oauth:2.0:oob",
        ["read", "write"],
        nil,
        api_base_url: conn.base_url
      )

    assert %Hunter.Application{scopes: ["read", "write"]} = app

    logged_in = Hunter.log_in(app, "kadaba@example.com", password2, conn.base_url)
    assert %Hunter.Client{access_token: token} = logged_in
    assert is_binary(token)

    %Status{id: id} = Status.create_status(logged_in, "auth flow works #hunterci")
    on_exit(fn -> destroy_quietly(logged_in, id) end)
    Status.destroy_status(logged_in, id)
  end

  test "blocks and unblocks a domain", %{conn: conn} do
    assert Domain.block_domain(conn, "blocked.example")
    on_exit(fn -> unblock_quietly(conn, "blocked.example") end)
    assert "blocked.example" in Domain.blocked_domains(conn)

    assert Domain.unblock_domain(conn, "blocked.example")
    refute "blocked.example" in Domain.blocked_domains(conn)
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

    %Status{id: id} = Status.create_status(logged_in, "oauth flow works #hunterci")
    on_exit(fn -> destroy_quietly(logged_in, id) end)
    Status.destroy_status(logged_in, id)
  end

  # Failure-path cleanup: on_exit nets that tolerate state already removed by
  # the test body's own assertions.
  defp destroy_quietly(conn, id) do
    Status.destroy_status(conn, id)
    :ok
  rescue
    Hunter.Error -> :ok
  end

  defp unfollow_quietly(conn, id) do
    Relationship.unfollow(conn, id)
    :ok
  rescue
    Hunter.Error -> :ok
  end

  defp destroy_list_quietly(conn, id) do
    Hunter.List.destroy_list(conn, id)
    :ok
  rescue
    Hunter.Error -> :ok
  end

  defp unblock_quietly(conn, domain) do
    Domain.unblock_domain(conn, domain)
    :ok
  rescue
    Hunter.Error -> :ok
  end

  defp unlock_quietly(conn) do
    Account.update_credentials(conn, %{locked: false})
    :ok
  rescue
    Hunter.Error -> :ok
  end
end
