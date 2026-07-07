defmodule Hunter.Api.Transformer do
  @moduledoc """
  Decodes Mastodon API JSON payloads into Hunter entity structs.
  """

  def transform(body, :account), do: Poison.decode!(body, as: %Hunter.Account{})

  def transform(body, :accounts), do: Poison.decode!(body, as: [%Hunter.Account{}])

  def transform(body, :application), do: Poison.decode!(body, as: %Hunter.Application{})

  def transform(body, :attachment), do: Poison.decode!(body, as: %Hunter.Attachment{})

  def transform(body, :card), do: Poison.decode!(body, as: %Hunter.Card{})

  def transform(body, :context) do
    Poison.decode!(
      body,
      as: %Hunter.Context{
        ancestors: [status_nested_struct()],
        descendants: [status_nested_struct()]
      }
    )
  end

  def transform(body, :instance), do: Poison.decode!(body, as: %Hunter.Instance{})

  def transform(body, :notification), do: Poison.decode!(body, as: notification_nested_struct())

  def transform(body, :notifications),
    do: Poison.decode!(body, as: [notification_nested_struct()])

  def transform(body, :status), do: Poison.decode!(body, as: status_nested_struct())

  def transform(body, :statuses), do: Poison.decode!(body, as: [status_nested_struct()])

  def transform(body, :relationship), do: Poison.decode!(body, as: %Hunter.Relationship{})

  def transform(body, :relationships), do: Poison.decode!(body, as: [%Hunter.Relationship{}])

  def transform(body, :report), do: Poison.decode!(body, as: %Hunter.Report{})

  def transform(body, :reports), do: Poison.decode!(body, as: [%Hunter.Report{}])

  def transform(body, :result) do
    Poison.decode!(
      body,
      as: %Hunter.Result{
        accounts: [%Hunter.Account{}],
        statuses: [status_nested_struct()],
        hashtags: [%Hunter.Tag{}]
      }
    )
  end

  def transform(body, _), do: Poison.decode!(body)

  defp status_nested_struct do
    %Hunter.Status{
      account: %Hunter.Account{},
      reblog: %Hunter.Status{},
      media_attachments: [%Hunter.Attachment{}],
      mentions: [%Hunter.Mention{}],
      tags: [%Hunter.Tag{}],
      application: %Hunter.Application{}
    }
  end

  defp notification_nested_struct do
    %Hunter.Notification{
      account: %Hunter.Account{},
      status: status_nested_struct()
    }
  end
end
