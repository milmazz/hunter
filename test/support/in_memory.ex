defmodule Hunter.Api.InMemory do
  @moduledoc """
  In-Memory Client (for testing purposes)
  """

  @behaviour Hunter.Api

  [
    %{name: :account, arity: 2, as: %Hunter.Account{}},
    %{name: :block, arity: 2, as: %Hunter.Relationship{}},
    %{name: :blocks, arity: 1, as: [%Hunter.Account{}]},
    %{name: :card_by_status, arity: 2, as: %Hunter.Card{}},
    %{name: :clear_notifications, arity: 1, as: %{}},
    %{name: :create_app, arity: 5, as: %Hunter.Application{}},
    %{name: :create_status, arity: 4, as: %Hunter.Status{}},
    %{name: :favourite, arity: 2, as: %Hunter.Status{}},
    %{name: :favourited_by, arity: 2, as: [%Hunter.Account{}]},
    %{name: :favourites, arity: 1, as: [%Hunter.Status{}]},
    %{name: :follow, arity: 2, as: %Hunter.Relationship{}},
    %{name: :follow_by_uri, arity: 2, as: %Hunter.Account{}},
    %{name: :follow_requests, arity: 1, as: [%Hunter.Account{}]},
    %{name: :followers, arity: 2, as: [%Hunter.Account{}]},
    %{name: :following, arity: 2, as: [%Hunter.Account{}]},
    %{name: :hashtag_timeline, arity: 3, as: [%Hunter.Status{}]},
    %{name: :home_timeline, arity: 2, as: [%Hunter.Status{}]},
    %{name: :instance_info, arity: 1, as: %Hunter.Instance{}},
    %{name: :mute, arity: 2, as: %Hunter.Relationship{}},
    %{name: :mutes, arity: 1, as: [%Hunter.Account{}]},
    %{name: :notification, arity: 2, as: %Hunter.Notification{}},
    %{name: :notifications, arity: 1, as: [%Hunter.Notification{}]},
    %{name: :public_timeline, arity: 2, as: [%Hunter.Status{}]},
    %{name: :reblog, arity: 2, as: %Hunter.Status{}},
    %{name: :reblogged_by, arity: 2, as: [%Hunter.Account{}]},
    %{name: :relationships, arity: 2, as: [%Hunter.Relationship{}]},
    %{name: :report, arity: 4, as: %Hunter.Report{}},
    %{name: :reports, arity: 1, as: [%Hunter.Report{}]},
    %{name: :search, arity: 3, as: %Hunter.Result{}},
    %{name: :search_account, arity: 2, as: [%Hunter.Account{}]},
    %{name: :status, arity: 2, as: %Hunter.Status{}},
    %{name: :status_context, arity: 2, as: %Hunter.Context{}},
    %{name: :statuses, arity: 3, as: [%Hunter.Status{}]},
    %{name: :unblock, arity: 2, as: %Hunter.Relationship{}},
    %{name: :unfavourite, arity: 2, as: %Hunter.Status{}},
    %{name: :unfollow, arity: 2, as: %Hunter.Relationship{}},
    %{name: :unmute, arity: 2, as: %Hunter.Relationship{}},
    %{name: :unreblog, arity: 2, as: %Hunter.Status{}},
    %{name: :upload_media, arity: 2, as: %Hunter.Attachment{}},
    %{name: :verify_credentials, arity: 1, as: %Hunter.Account{}},
  ]
  |> Enum.map(fn %{name: name, arity: arity, as: as} ->
    params = for _ <- 1..arity, do: {:_, [], nil}
    as = Macro.escape(as)

    def unquote(name)(unquote_splicing(params)) do
      file = to_string(unquote(name))

      "../fixtures/#{file}.json"
      |> Path.expand(__DIR__)
      |> File.read!()
      |> Poison.decode!(as: unquote(as))
    end
  end)

  def destroy_status(_, _), do: true
  def follow_request_action(_, _, _), do: true
end
