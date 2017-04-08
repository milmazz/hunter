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
  @type t :: %__MODULE__{
    uri: URI.t,
    title: String.t,
    description: String.t,
    email: String.t
  }

  defstruct [:uri, :title, :description, :email]
end
