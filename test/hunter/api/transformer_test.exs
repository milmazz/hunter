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

    assert [%Hunter.Emoji{shortcode: "blobcat", visible_in_picker: true, category: "cats"}] =
             account.emojis
  end

  test "decodes modern account fields" do
    account = transform("account", :account)

    assert account.bot == false
    assert account.group == false
    assert account.discoverable == true
    assert account.noindex == false
    assert account.suspended == false
    assert account.limited == false
    assert account.last_status_at == "2026-07-01"
    assert account.hide_collections == false
    assert account.uri == "https://mastodon.example/users/milmazz"
    assert account.attribution_domains == ["milmazz.uno"]

    assert [%Hunter.Field{name: "Website", verified_at: "2026-01-15T10:00:00.000Z"}] =
             account.fields

    assert [%Hunter.Role{id: "3", name: "Owner", color: "#ff3838"}] = account.roles
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

  test "decodes modern status fields" do
    status = transform("status", :status)

    assert status.edited_at == "2026-06-30T12:00:00.000Z"
    assert status.bookmarked == true
    assert status.pinned == false
    assert status.replies_count == 2
    assert status.text == nil

    assert [%Hunter.Emoji{shortcode: "blobcat"}] = status.emojis

    assert [%Hunter.Tag{id: "541", following: true, featuring: false, history: [history]}] =
             status.tags

    assert history["uses"] == "24"

    assert [%Hunter.Attachment{blurhash: "UBL_:rOpGG-;~qRjWBay0fM{ofofoLWBWVj["}] =
             status.media_attachments

    assert %Hunter.Card{embed_url: "", blurhash: "UBL_:rOpGG-;~qRjWBay0fM{ofofoLWBWVj["} =
             status.card

    assert [%Hunter.Card.Author{name: "José Valim", account: nil}] = status.card.authors

    assert %Hunter.Poll{id: "34830", multiple: false, votes_count: 10} = status.poll
    assert [%Hunter.Poll.Option{title: "accept", votes_count: 6} | _] = status.poll.options

    assert [%Hunter.FilterResult{keyword_matches: ["bad word"]} = filter_result] =
             status.filtered

    assert %Hunter.Filter{id: "19972", filter_action: "warn"} = filter_result.filter

    assert %Hunter.Quote{state: "accepted", quoted_status_id: "103270115826048000"} =
             status.quote

    assert status.quote_approval["current_user"] == "automatic"
  end

  test "decodes a status source" do
    source = transform("status_source", :status_source)

    assert %Hunter.StatusSource{id: "103270115826048975"} = source
    assert source.text == "Testing #elixir with @kadaba"
    assert source.spoiler_text == ""
  end

  test "decodes a status edit history" do
    assert [edit] = transform_list("status_edit", :status_edits)

    assert %Hunter.StatusEdit{sensitive: false} = edit
    assert edit.content =~ "(edited)"
    assert %Hunter.Account{username: "milmazz"} = edit.account
    assert [%Hunter.Attachment{id: "22345792"}] = edit.media_attachments
    assert %{"options" => [%{"title" => "accept"} | _]} = edit.poll
  end

  test "decodes a poll" do
    poll = transform("poll", :poll)

    assert %Hunter.Poll{id: "34830", expired: false, voters_count: 10} = poll
    assert poll.voted == true
    assert poll.own_votes == [1]
    assert [%Hunter.Poll.Option{title: "accept", votes_count: 6}, _] = poll.options
  end

  test "decodes a filter with keywords and statuses" do
    filter = transform("filter", :filter)

    assert %Hunter.Filter{id: "19972", title: "Test filter", context: ["home"]} = filter
    assert [%Hunter.FilterKeyword{keyword: "bad word", whole_word: false}] = filter.keywords
    assert [%Hunter.FilterStatus{status_id: "109031743575371913"}] = filter.statuses
  end

  test "decodes a list of filters" do
    assert [%Hunter.Filter{title: "Test filter"}] = transform_list("filter", :filters)
  end

  test "decodes a translation" do
    translation = transform("translation", :translation)

    assert %Hunter.Translation{language: "es", detected_source_language: "en"} = translation
    assert translation.content == "<p>Hola mundo</p>"
    assert translation.provider == "DeepL.com"
    assert [%{"description" => "prueba de medios"}] = translation.media_attachments
  end

  test "decodes a scheduled status" do
    scheduled = transform("scheduled_status", :scheduled_status)

    assert %Hunter.ScheduledStatus{id: "3221", scheduled_at: "2026-07-20T13:00:00.000Z"} =
             scheduled

    assert scheduled.params["text"] == "test content"
    assert [%Hunter.Attachment{id: "22345792", type: "image"}] = scheduled.media_attachments
  end

  test "decodes a list of scheduled statuses" do
    assert [%Hunter.ScheduledStatus{id: "3221"}] =
             transform_list("scheduled_status", :scheduled_statuses)
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
    assert notification.group_key == "ungrouped-34975861"
    assert notification.report == nil
    assert notification.event == nil
    assert notification.moderation_warning == nil
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
    assert [%Hunter.Rule{text: "Be excellent to each other"}] = instance.rules
  end

  test "decodes a relationship" do
    relationship = transform("relationship", :relationship)

    assert %Hunter.Relationship{following: true, blocking: false} = relationship
    assert relationship.showing_reblogs == true
    assert relationship.notifying == false
    assert relationship.languages == ["en", "es"]
    assert relationship.blocked_by == false
    assert relationship.muting_notifications == false
    assert relationship.muting_expires_at == nil
    assert relationship.requested_by == false
    assert relationship.endorsed == false
    assert relationship.note == "college friend"
  end

  test "decodes a list of relationships" do
    assert [%Hunter.Relationship{following: true}] =
             transform_list("relationship", :relationships)
  end

  test "decodes a list" do
    assert %Hunter.List{id: "12249", title: "Friends", replies_policy: "followed"} =
             transform("list", :list)
  end

  test "decodes a list of lists" do
    assert [%Hunter.List{title: "Friends", exclusive: false}] = transform_list("list", :lists)
  end

  test "decodes a conversation with nested accounts and last status" do
    conversation = transform("conversation", :conversation)

    assert %Hunter.Conversation{id: "418450", unread: true} = conversation
    assert [%Hunter.Account{username: "kadaba"}] = conversation.accounts
    assert %Hunter.Status{visibility: "direct"} = conversation.last_status
  end

  test "decodes a list of conversations" do
    assert [%Hunter.Conversation{id: "418450"}] =
             transform_list("conversation", :conversations)
  end

  test "decodes markers keyed by timeline" do
    markers = transform("markers", :markers)

    assert %Hunter.Marker{last_read_id: "103270115826048975", version: 462} = markers["home"]
    assert %Hunter.Marker{last_read_id: "34975861"} = markers["notifications"]
  end

  test "decodes a suggestion" do
    suggestion = transform("suggestion", :suggestion)

    assert %Hunter.Suggestion{sources: ["similar_to_recently_followed"]} = suggestion
    assert %Hunter.Account{username: "kadaba"} = suggestion.account
  end

  test "decodes a list of suggestions" do
    assert [%Hunter.Suggestion{source: "past_interactions"}] =
             transform_list("suggestion", :suggestions)
  end

  test "decodes a featured tag" do
    featured_tag = transform("featured_tag", :featured_tag)

    assert %Hunter.FeaturedTag{id: "627", name: "elixir", statuses_count: 20} = featured_tag
    assert featured_tag.last_status_at == "2026-07-01"
  end

  test "decodes a list of featured tags" do
    assert [%Hunter.FeaturedTag{name: "elixir"}] =
             transform_list("featured_tag", :featured_tags)
  end

  test "decodes an announcement with reactions" do
    announcement = transform("announcement", :announcement)

    assert %Hunter.Announcement{id: "8", all_day: false, read: true} = announcement
    assert [%{"username" => "kadaba"}] = announcement.mentions
    assert [%Hunter.Tag{name: "elixir"}] = announcement.tags

    assert [%Hunter.Announcement.Reaction{name: "bongoCat", count: 9, me: false}] =
             announcement.reactions
  end

  test "decodes a list of announcements" do
    assert [%Hunter.Announcement{id: "8"}] = transform_list("announcement", :announcements)
  end

  test "decodes preferences" do
    preferences = transform("preferences", :preferences)

    assert %Hunter.Preferences{} = preferences
    assert preferences."posting:default:visibility" == "public"
    assert preferences."posting:default:sensitive" == false
    assert preferences."reading:expand:media" == "default"
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
    assert attachment.meta["focus"]["x"] == 0.5
    assert attachment.blurhash == "UBL_:rOpGG-;~qRjWBay0fM{ofofoLWBWVj["
    assert attachment.preview_remote_url == nil
  end

  test "decodes a notification policy" do
    policy = transform("notification_policy", :notification_policy)

    assert %Hunter.NotificationPolicy{for_not_following: "accept"} = policy
    assert policy.for_private_mentions == "filter"
    assert policy.summary["pending_requests_count"] == 3
  end

  test "decodes a notification request with nested account and status" do
    request = transform("notification_request", :notification_request)

    assert %Hunter.NotificationRequest{id: "112456967201894256"} = request
    assert request.notifications_count == "5"
    assert %Hunter.Account{username: "kadaba"} = request.account
    assert %Hunter.Status{visibility: "public"} = request.last_status
  end

  test "decodes a list of notification requests" do
    assert [%Hunter.NotificationRequest{notifications_count: "5"}] =
             transform_list("notification_request", :notification_requests)
  end

  test "decodes a notification group" do
    group = transform("notification_group", :notification_group)

    assert %Hunter.NotificationGroup{type: "favourite", notifications_count: 2} = group
    assert group.group_key == "favourite-103270115826048975"
    assert group.sample_account_ids == ["8039", "23634"]
    assert group.status_id == "103270115826048975"
  end

  test "decodes a web push subscription" do
    subscription = transform("web_push_subscription", :web_push_subscription)

    assert %Hunter.WebPushSubscription{id: "328183", standard: true} = subscription
    assert subscription.alerts["mention"] == true
    assert subscription.alerts["admin.report"] == false
  end

  test "decodes a rule" do
    rule = transform("rule", :rule)

    assert %Hunter.Rule{id: "2"} = rule
    assert rule.text =~ "No racism"
    assert rule.hint =~ "Transphobic behavior"
  end

  test "decodes a list of rules" do
    assert [%Hunter.Rule{id: "2"}] = transform_list("rule", :rules)
  end

  test "decodes an extended description" do
    assert %Hunter.ExtendedDescription{updated_at: "2026-06-15T00:00:00.000Z"} =
             transform("extended_description", :extended_description)
  end

  test "decodes a privacy policy" do
    assert %Hunter.PrivacyPolicy{updated_at: "2026-06-15T00:00:00.000Z"} =
             transform("privacy_policy", :privacy_policy)
  end

  test "decodes terms of service" do
    terms = transform("terms_of_service", :terms_of_service)

    assert %Hunter.TermsOfService{effective_date: "2026-06-15", effective: true} = terms
    assert terms.succeeded_by == nil
  end

  test "decodes a domain block" do
    domain_block = transform("domain_block", :domain_block)

    assert %Hunter.DomainBlock{domain: "spam.example", severity: "suspend"} = domain_block
    assert domain_block.comment == "spam instance"
  end

  test "decodes a list of domain blocks" do
    assert [%Hunter.DomainBlock{domain: "spam.example"}] =
             transform_list("domain_block", :domain_blocks)
  end

  test "decodes a collection with items" do
    collection = transform("collection", :collection)

    assert %Hunter.Collection{id: "118", name: "Elixir folks", item_count: 1} = collection
    assert collection.local == true

    assert [%Hunter.Collection.Item{id: "310", account_id: "8039", state: "accepted"}] =
             collection.items
  end

  test "decodes an annual report" do
    annual_report = transform("annual_report", :annual_report)

    assert %Hunter.AnnualReport{year: 2025, schema_version: 2} = annual_report
    assert annual_report.account_id == "23634"
    assert annual_report.data["archetype"] == "oracle"
  end

  test "decodes an application with modern fields" do
    application =
      Transformer.transform(
        ~s({"name": "hunter", "website": null, "scopes": ["read"], "redirect_uris": ["urn:ietf:wg:oauth:2.0:oob"], "client_id": "abc", "client_secret": "def", "client_secret_expires_at": 0}),
        :application
      )

    assert %Hunter.Application{name: "hunter", scopes: ["read"]} = application
    assert application.redirect_uris == ["urn:ietf:wg:oauth:2.0:oob"]
    assert application.client_secret_expires_at == 0
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
