defmodule Hunter.Api.InMemory do
  @behaviour Hunter.Api

  def verify_credentials(_) do
    %Hunter.Account{}
  end

  def account(_, _) do
     %Hunter.Account{}
  end

  def followers(_, _) do
    [%Hunter.Account{}]
  end

  def following(_, _) do
    [%Hunter.Account{}]
  end

  def follow_by_uri(_, _) do
    %Hunter.Account{}
  end

  def create_app(_, _, _, _, _) do
    %Hunter.Application{}
  end

  def upload_media(_, _) do
    %Hunter.Attachment{}
  end

  def relationships(_) do
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

  def favourite(_, _) do
    %Hunter.Status{}
  end

  def unfavourite(_, _) do
    %Hunter.Status{}
  end

  def statuses(_, _, _) do
    [%Hunter.Status{}]
  end

  def home_timeline(_, _) do
    [%Hunter.Status{}]
  end

  def public_timeline(_, _) do

  end

  def hashtag_timeline(_, _, _) do

  end
end
