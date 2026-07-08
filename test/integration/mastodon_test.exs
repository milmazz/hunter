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
    assert %Instance{uri: uri, version: version} = Instance.instance_info(conn)
    assert is_binary(uri)
    assert is_binary(version)
  end

  test "status lifecycle: create, fetch, favourite, reblog, destroy", %{
    conn: conn,
    conn2: conn2
  } do
    text = "hunter integration test #hunterci"

    status = Status.create_status(conn, text)
    assert %Status{id: id, content: content} = status
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
    assert [%Relationship{following: true}] = Relationship.relationships(conn, [id2])

    %Status{id: status_id} = Status.create_status(conn2, "hello @hunter #hunterci")

    eventually(fn ->
      notifications = Notification.notifications(conn)

      assert Enum.any?(notifications, fn n ->
               n.type == "mention" and n.account.username == "kadaba"
             end)
    end)

    assert %Relationship{following: false} = Relationship.unfollow(conn, id2)
    Status.destroy_status(conn2, status_id)
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

    assert Enum.any?(attachments, &(&1.id == media_id))
    Status.destroy_status(conn, id)
  end

  test "query parameters take effect server-side", %{conn: conn} do
    %Account{id: account_id} = Account.verify_credentials(conn)

    %Status{id: id1} = Status.create_status(conn, "pagination one #hunterci")
    %Status{id: id2} = Status.create_status(conn, "pagination two #hunterci")

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
    Status.destroy_status(logged_in, id)
  end

  test "blocks and unblocks a domain", %{conn: conn} do
    assert Domain.block_domain(conn, "blocked.example")
    assert "blocked.example" in Domain.blocked_domains(conn)

    assert Domain.unblock_domain(conn, "blocked.example")
    refute "blocked.example" in Domain.blocked_domains(conn)
  end
end
