defmodule Hunter.Application do
  @moduledoc """
  Application entity

  This module defines a `Hunter.Application` struct and the main functions
  for working with Applications.

  ## Fields

    * `name` -  name of the application
    * `website` - homepage URL of the application
    * `scope` - access scopes
    * `redirect_uri` -

  ## Scopes

  * `read` - read data
  * `write` - post statuses and upload media for statuses
  * `follow` - follow, unfollow, block, unblock

Multiple scopes can be requested during the authorization phase with the `scope` query param

  """
  @hunter_api Application.get_env(:hunter, :hunter_api)

  @type t :: %__MODULE__{
    name: String.t,
    redirect_uri: URI.t,
    scopes: String.t,
    website: URI.t
  }

  @derive [Poison.Encoder]
  defstruct [:name, :redirect_uri, :scopes, :website]

  @doc """
  Register a new OAuth client app on the target instance

  ## Parameters

    * `conn` - connection credentials
    * `name` -
    * `redirect_uri` -
    * `scopes` -
    * `website` -

  """
  @spec create_app(Hunter.Client.t, String.t, URI.t, String.t, String.t) :: Hunter.Application.t
  def create_app(conn, name, redirect_uri, scopes \\ "read", website \\ nil) do
    @hunter_api.create_app(conn, name, redirect_uri, scopes, website)
  end
end
