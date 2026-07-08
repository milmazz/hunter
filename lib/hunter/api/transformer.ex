defmodule Hunter.Api.Transformer do
  # Decodes Mastodon API JSON payloads into Hunter entity structs.
  @moduledoc false

  def transform(body, :account), do: Poison.decode!(body, as: account_nested_struct())

  def transform(body, :accounts), do: Poison.decode!(body, as: [account_nested_struct()])

  def transform(body, :application), do: Poison.decode!(body, as: %Hunter.Application{})

  def transform(body, :attachment), do: Poison.decode!(body, as: %Hunter.Attachment{})

  def transform(body, :context) do
    Poison.decode!(
      body,
      as: %Hunter.Context{
        ancestors: [status_nested_struct()],
        descendants: [status_nested_struct()]
      }
    )
  end

  def transform(body, :instance),
    do: Poison.decode!(body, as: %Hunter.Instance{rules: [%Hunter.Rule{}]})

  def transform(body, :notification), do: Poison.decode!(body, as: notification_nested_struct())

  def transform(body, :notifications),
    do: Poison.decode!(body, as: [notification_nested_struct()])

  def transform(body, :status), do: Poison.decode!(body, as: status_nested_struct())

  def transform(body, :statuses), do: Poison.decode!(body, as: [status_nested_struct()])

  def transform(body, :status_source), do: Poison.decode!(body, as: %Hunter.StatusSource{})

  def transform(body, :status_edits) do
    Poison.decode!(
      body,
      as: [
        %Hunter.StatusEdit{
          account: account_nested_struct(),
          media_attachments: [%Hunter.Attachment{}],
          emojis: [%Hunter.Emoji{}]
        }
      ]
    )
  end

  def transform(body, :notification_policy),
    do: Poison.decode!(body, as: %Hunter.NotificationPolicy{})

  def transform(body, :notification_request),
    do: Poison.decode!(body, as: notification_request_nested_struct())

  def transform(body, :notification_requests),
    do: Poison.decode!(body, as: [notification_request_nested_struct()])

  def transform(body, :notification_group),
    do: Poison.decode!(body, as: notification_group_nested_struct())

  def transform(body, :notification_groups),
    do: Poison.decode!(body, as: [notification_group_nested_struct()])

  def transform(body, :web_push_subscription),
    do: Poison.decode!(body, as: %Hunter.WebPushSubscription{})

  def transform(body, :rule), do: Poison.decode!(body, as: %Hunter.Rule{})

  def transform(body, :rules), do: Poison.decode!(body, as: [%Hunter.Rule{}])

  def transform(body, :extended_description),
    do: Poison.decode!(body, as: %Hunter.ExtendedDescription{})

  def transform(body, :privacy_policy), do: Poison.decode!(body, as: %Hunter.PrivacyPolicy{})

  def transform(body, :terms_of_service), do: Poison.decode!(body, as: %Hunter.TermsOfService{})

  def transform(body, :domain_block), do: Poison.decode!(body, as: %Hunter.DomainBlock{})

  def transform(body, :domain_blocks), do: Poison.decode!(body, as: [%Hunter.DomainBlock{}])

  def transform(body, :collection), do: Poison.decode!(body, as: collection_nested_struct())

  def transform(body, :collections), do: Poison.decode!(body, as: [collection_nested_struct()])

  def transform(body, :annual_report), do: Poison.decode!(body, as: %Hunter.AnnualReport{})

  def transform(body, :annual_reports), do: Poison.decode!(body, as: [%Hunter.AnnualReport{}])

  def transform(body, :list), do: Poison.decode!(body, as: %Hunter.List{})

  def transform(body, :lists), do: Poison.decode!(body, as: [%Hunter.List{}])

  def transform(body, :conversation), do: Poison.decode!(body, as: conversation_nested_struct())

  def transform(body, :conversations),
    do: Poison.decode!(body, as: [conversation_nested_struct()])

  def transform(body, :markers) do
    Poison.decode!(
      body,
      as: %{"home" => %Hunter.Marker{}, "notifications" => %Hunter.Marker{}}
    )
  end

  def transform(body, :suggestion), do: Poison.decode!(body, as: suggestion_nested_struct())

  def transform(body, :suggestions), do: Poison.decode!(body, as: [suggestion_nested_struct()])

  def transform(body, :featured_tag), do: Poison.decode!(body, as: %Hunter.FeaturedTag{})

  def transform(body, :featured_tags), do: Poison.decode!(body, as: [%Hunter.FeaturedTag{}])

  def transform(body, :announcement), do: Poison.decode!(body, as: announcement_nested_struct())

  def transform(body, :announcements),
    do: Poison.decode!(body, as: [announcement_nested_struct()])

  def transform(body, :preferences), do: Poison.decode!(body, as: %Hunter.Preferences{})

  def transform(body, :poll), do: Poison.decode!(body, as: poll_nested_struct())

  def transform(body, :filter), do: Poison.decode!(body, as: filter_nested_struct())

  def transform(body, :filters), do: Poison.decode!(body, as: [filter_nested_struct()])

  def transform(body, :filter_keyword), do: Poison.decode!(body, as: %Hunter.FilterKeyword{})

  def transform(body, :filter_keywords), do: Poison.decode!(body, as: [%Hunter.FilterKeyword{}])

  def transform(body, :filter_status), do: Poison.decode!(body, as: %Hunter.FilterStatus{})

  def transform(body, :filter_statuses), do: Poison.decode!(body, as: [%Hunter.FilterStatus{}])

  def transform(body, :translation), do: Poison.decode!(body, as: %Hunter.Translation{})

  def transform(body, :scheduled_status),
    do: Poison.decode!(body, as: scheduled_status_nested_struct())

  def transform(body, :scheduled_statuses),
    do: Poison.decode!(body, as: [scheduled_status_nested_struct()])

  def transform(body, :relationship), do: Poison.decode!(body, as: %Hunter.Relationship{})

  def transform(body, :relationships), do: Poison.decode!(body, as: [%Hunter.Relationship{}])

  def transform(body, :report), do: Poison.decode!(body, as: %Hunter.Report{})

  def transform(body, :result) do
    Poison.decode!(
      body,
      as: %Hunter.Result{
        accounts: [account_nested_struct()],
        statuses: [status_nested_struct()],
        hashtags: [%Hunter.Tag{}]
      }
    )
  end

  def transform(body, _), do: Poison.decode!(body)

  defp account_nested_struct do
    %Hunter.Account{
      emojis: [%Hunter.Emoji{}],
      fields: [%Hunter.Field{}],
      roles: [%Hunter.Role{}]
    }
  end

  defp status_nested_struct do
    %Hunter.Status{
      account: account_nested_struct(),
      reblog: %Hunter.Status{},
      media_attachments: [%Hunter.Attachment{}],
      mentions: [%Hunter.Mention{}],
      tags: [%Hunter.Tag{}],
      emojis: [%Hunter.Emoji{}],
      application: %Hunter.Application{},
      card: card_nested_struct(),
      poll: poll_nested_struct(),
      filtered: [%Hunter.FilterResult{filter: filter_nested_struct()}],
      quote: %Hunter.Quote{quoted_status: %Hunter.Status{account: account_nested_struct()}}
    }
  end

  defp poll_nested_struct do
    %Hunter.Poll{options: [%Hunter.Poll.Option{}], emojis: [%Hunter.Emoji{}]}
  end

  defp filter_nested_struct do
    %Hunter.Filter{keywords: [%Hunter.FilterKeyword{}], statuses: [%Hunter.FilterStatus{}]}
  end

  defp scheduled_status_nested_struct do
    %Hunter.ScheduledStatus{media_attachments: [%Hunter.Attachment{}]}
  end

  defp conversation_nested_struct do
    %Hunter.Conversation{
      accounts: [account_nested_struct()],
      last_status: status_nested_struct()
    }
  end

  defp suggestion_nested_struct do
    %Hunter.Suggestion{account: account_nested_struct()}
  end

  defp announcement_nested_struct do
    %Hunter.Announcement{
      tags: [%Hunter.Tag{}],
      emojis: [%Hunter.Emoji{}],
      reactions: [%Hunter.Announcement.Reaction{}]
    }
  end

  defp notification_request_nested_struct do
    %Hunter.NotificationRequest{
      account: account_nested_struct(),
      last_status: status_nested_struct()
    }
  end

  defp notification_group_nested_struct do
    %Hunter.NotificationGroup{report: %Hunter.Report{}}
  end

  defp collection_nested_struct do
    %Hunter.Collection{items: [%Hunter.Collection.Item{}]}
  end

  defp card_nested_struct do
    %Hunter.Card{authors: [%Hunter.Card.Author{account: account_nested_struct()}]}
  end

  defp notification_nested_struct do
    %Hunter.Notification{
      account: account_nested_struct(),
      status: status_nested_struct(),
      report: %Hunter.Report{}
    }
  end
end
