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
    uri: URI.t,
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

  """
  @spec instance_info(Hunter.Client.t) :: Hunter.Instance.t
  def instance_info(conn) do
    @hunter_api.instance_info(conn)
  end
end
