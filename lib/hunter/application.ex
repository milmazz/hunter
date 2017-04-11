defmodule Hunter.Application do
  @moduledoc """
  Application entity

  This module defines a `Hunter.Application` struct and the main functions
  for working with Applications.

  ## Fields

    * `id` -  identifier
    * `client_id` - client id
    * `client_secret` - client secret

  """
  @hunter_api Application.get_env(:hunter, :hunter_api)

  @type t :: %__MODULE__{
    id: non_neg_integer,
    client_id: String.t,
    client_secret: String.t
  }

  @derive [Poison.Encoder]
  defstruct [:id, :client_id, :client_secret]

  @doc """
  Register a new OAuth client app on the target instance

  ## Parameters

    * `conn` - connection credentials
    * `name` - name of your application
    * `redirect_uri` - where the user should be redirected after authorization,
      default: `urn:ietf:wg:oauth:2.0:oob` (no redirect)
    * `scopes` - scope list, see the scope section for more details, default: `read`
    * `website` - URL to the homepage of your app, default: `nil`

  ## Scopes

    * `read` - read data
    * `write` - post statuses and upload media for statuses
    * `follow` - follow, unfollow, block, unblock

  Multiple scopes can be requested during the authorization phase with the `scope` query param

  """
  @spec create_app(Hunter.Client.t, String.t, URI.t, String.t, String.t) :: Hunter.Application.t
  def create_app(conn, name, redirect_uri \\ "urn:ietf:wg:oauth:2.0:oob", scopes \\ "read", website \\ nil) do
    @hunter_api.create_app(conn, name, redirect_uri, scopes, website)

    # TODO: Store this credentials because these values are required for OAuth Authentication
    # These values should be requested in the app itself from the API for each
    # new app install + mastodon domain combo, and stored in the app for future requests.
  end
end
