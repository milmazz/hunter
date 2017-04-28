defmodule Hunter.Instance do
  @moduledoc """
  Instance entity

  This module defines a `Hunter.Instance` struct and the main functions
  for working with Instances.

  ## Fields

    * `uri` - URI of the current instance
    * `title` - The instance's title
    * `description` - A description for the instance
    * `email` - An email address which can be used to contact the instance administrator

  """
  @hunter_api Hunter.Config.hunter_api()

  @type t :: %__MODULE__{
    uri: String.t,
    title: String.t,
    description: String.t,
    email: String.t
  }

  @derive [Poison.Encoder]
  defstruct [:uri, :title, :description, :email]

  @doc """
  Retrieve instance information

  ## Parameters

    * `conn` - connection credentials

  ## Examples

      iex> conn = Hunter.new([base_url: "https://social.lou.lt", bearer_token: "123456"])
      %Hunter.Client{base_url: "https://social.lou.lt", bearer_token: "123456"}
      iex> Hunter.Instance.instance_info(conn)
      %Hunter.Instance{description: "Mostly French  instance - <a href=\\"/about/more#rules\\">Read full description</a> for rules.",
                email: "maxime+mastodon@melinon.fr", title: "Loultstodon",
                uri: "social.lou.lt"}

  """
  @spec instance_info(Hunter.Client.t) :: Hunter.Instance.t
  def instance_info(conn) do
    @hunter_api.instance_info(conn)
  end
end
