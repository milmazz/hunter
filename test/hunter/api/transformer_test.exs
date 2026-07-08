defmodule Hunter.Api.TransformerTest do
  use ExUnit.Case, async: true

  alias Hunter.Api.Transformer

  test "decodes an account" do
    account = transform("account", :account)

    assert %Hunter.Account{} = account
    assert account.username == "milmazz"
    assert account.acct == "milmazz"
    assert account.display_name == "Milton Mazzarri"
    assert account.followers_count == 118
    assert account.url == "https://mastodon.example/@milmazz"

    assert [%Hunter.Emoji{shortcode: "blobcat", visible_in_picker: true}] = account.emojis
  end

  test "decodes a list of accounts" do
    assert [%Hunter.Account{username: "milmazz"}] =
             transform_list("account", :accounts)
  end

  test "decodes a status with nested entities" do
    status = transform("status", :status)

    assert %Hunter.Status{visibility: "public", language: "en"} = status
    assert status.reblogs_count == 6
    assert %Hunter.Account{username: "milmazz"} = status.account
    assert [%Hunter.Attachment{id: "22345792", type: "image"}] = status.media_attachments
    assert [%Hunter.Mention{username: "kadaba", acct: "kadaba"}] = status.mentions
    assert [%Hunter.Tag{name: "elixir"}] = status.tags
    assert %Hunter.Card{title: "The Elixir programming language", type: "link"} = status.card
    assert status.reblog == nil
  end

  test "decodes a list of statuses" do
    assert [%Hunter.Status{account: %Hunter.Account{username: "milmazz"}}] =
             transform_list("status", :statuses)
  end

  test "decodes a notification with nested account and status" do
    notification = transform("notification", :notification)

    assert %Hunter.Notification{type: "mention"} = notification
    assert %Hunter.Account{username: "kadaba"} = notification.account
    assert %Hunter.Status{content: "<p>hello @milmazz</p>"} = notification.status
  end

  test "decodes a list of notifications" do
    assert [%Hunter.Notification{type: "mention"}] =
             transform_list("notification", :notifications)
  end

  test "decodes a context with status ancestors and descendants" do
    context = transform("context", :context)

    assert %Hunter.Context{} = context
    assert [%Hunter.Status{content: "<p>parent</p>"}] = context.ancestors
    assert [%Hunter.Status{content: "<p>reply</p>"}] = context.descendants
  end

  test "decodes a v2 instance" do
    instance = transform("instance", :instance)

    assert %Hunter.Instance{domain: "mastodon.example", version: "4.3.8"} = instance
    assert instance.contact["email"] == "admin@mastodon.example"
    assert instance.configuration["urls"]["streaming"] == "wss://mastodon.example"
    assert [%{"text" => "Be excellent to each other"}] = instance.rules
  end

  test "decodes a relationship" do
    assert %Hunter.Relationship{following: true, blocking: false} =
             transform("relationship", :relationship)
  end

  test "decodes a list of relationships" do
    assert [%Hunter.Relationship{following: true}] =
             transform_list("relationship", :relationships)
  end

  test "decodes a report" do
    assert %Hunter.Report{id: "48914", action_taken: false} = transform("report", :report)
  end

  test "decodes a search result with nested accounts, statuses, and hashtags" do
    result = transform("result", :result)

    assert %Hunter.Result{} = result
    assert [%Hunter.Account{username: "milmazz"}] = result.accounts
    assert [%Hunter.Status{visibility: "public"}] = result.statuses

    assert [%Hunter.Tag{name: "elixir", url: "https://mastodon.example/tags/elixir"}] =
             result.hashtags
  end

  test "decodes an attachment" do
    attachment = transform("attachment", :attachment)

    assert %Hunter.Attachment{type: "image", description: "test media"} = attachment
    assert attachment.meta["original"]["width"] == 640
  end

  test "falls back to a plain map for unknown entities" do
    assert %{"id" => "48914"} = transform("report", :unknown)
  end

  defp transform(fixture_name, to) do
    fixture_name
    |> fixture()
    |> Transformer.transform(to)
  end

  defp transform_list(fixture_name, to) do
    Transformer.transform("[" <> fixture(fixture_name) <> "]", to)
  end

  defp fixture(name) do
    [__DIR__, "..", "..", "fixtures", name <> ".json"]
    |> Path.join()
    |> Path.expand()
    |> File.read!()
  end
end
