defmodule Hunter.Api.InMemory do
  @moduledoc """
  In-Memory Client (for testing purposes)
  """

  @behaviour Hunter.Api

  [
    %{name: :verify_credentials, arity: 1, as: %Hunter.Account{}},
    %{name: :account, arity: 2, as: %Hunter.Account{}},
    %{name: :followers, arity: 2, as: [%Hunter.Account{}]},
    %{name: :following, arity: 2, as: [%Hunter.Account{}]},
    %{name: :follow_by_uri, arity: 2, as: %Hunter.Account{}}
  ]
  |> Enum.map(fn %{name: name, arity: arity, as: as} ->
    params = for _ <- 1..arity, do: {:_, [], nil}
    as = Macro.escape(as)

    def unquote(name)(unquote_splicing(params)) do
      file = unquote(name) |> to_string()

      "../fixtures/#{file}.json"
      |> Path.expand(__DIR__)
      |> File.read!()
      |> Poison.decode!(as: unquote(as))
    end
  end)

  def search_account(_, _) do
    [%Hunter.Account{}]
  end

  def blocks(_) do
    [%Hunter.Account{}]
  end

  def follow_requests(_) do
    [%Hunter.Account{}]
  end

  def mutes(_) do
    [%Hunter.Account{}]
  end

  def create_app(_, _, _, _, _) do
    %Hunter.Application{}
  end

  def upload_media(_, _) do
    %Hunter.Attachment{}
  end

  def relationships(_, _) do
    [%Hunter.Relationship{}]
  end

  def follow(_, _) do
    %Hunter.Relationship{}
  end

  def unfollow(_, _) do
    %Hunter.Relationship{}
  end

  def block(_, _) do
    %Hunter.Relationship{}
  end

  def unblock(_, _) do
    %Hunter.Relationship{}
  end

  def mute(_, _) do
    %Hunter.Relationship{}
  end

  def unmute(_, _) do
    %Hunter.Relationship{}
  end

  def search(_, _, _) do
  end

  def create_status(_, _, _, _) do
  end

  def status(_, _) do
    %Hunter.Status{}
  end

  def destroy_status(_, _) do
    true
  end

  def reblog(_, _) do
    %Hunter.Status{}
  end

  def unreblog(_, _) do
    %Hunter.Status{}
  end

  def reblogged_by(_, _) do
    [%Hunter.Account{}]
  end

  def favourite(_, _) do
    %Hunter.Status{}
  end

  def unfavourite(_, _) do
    %Hunter.Status{}
  end

  def favourites(_) do
    [%Hunter.Status{}]
  end

  def favourited_by(_, _) do
    [%Hunter.Account{}]
  end

  def statuses(_, _, _) do
    [%Hunter.Status{}]
  end

  def home_timeline(_, _) do
    [%Hunter.Status{}]
  end

  def public_timeline(_, _) do
    [%Hunter.Status{}]
  end

  def hashtag_timeline(_, _, _) do
    [%Hunter.Status{}]
  end

  def instance_info(_) do
    %Hunter.Instance{}
  end

  def notifications(_) do
    [%Hunter.Notification{}]
  end

  def notification(_, _) do
    %Hunter.Notification{}
  end

  def clear_notifications(_) do
    %{}
  end

  def reports(_) do
    [%Hunter.Report{}]
  end

  def report(_, _, _, _) do
    %Hunter.Report{}
  end

  def status_context(_, _) do
    %Hunter.Context{}
  end

  def card_by_status(_, _) do
    %Hunter.Card{}
  end
end
