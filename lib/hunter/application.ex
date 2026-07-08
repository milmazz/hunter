defmodule Hunter.Application do
  @moduledoc """
  Application entity

  This module defines a `Hunter.Application` struct and the main functions
  for working with Applications.

  The struct covers both the `Application` entity embedded in statuses
  (`name` and `website` only) and the `CredentialApplication` entity returned
  when registering an app (which adds the client credentials).

  ## Fields

    * `id` -  identifier
    * `name` - the name of the application
    * `website` - the website associated with the application, if any
    * `client_id` - client id
    * `client_secret` - client secret
    * `client_secret_expires_at` - when the client secret expires, currently
      always `0` (never expires)
    * `scopes` - scopes requested when the app was registered
    * `redirect_uris` - redirect URIs the app was registered with
    * `redirect_uri` - redirect URI the app was registered with (deprecated
      since Mastodon 4.3 in favor of `redirect_uris`)

  """
  alias Hunter.Config

  @type t :: %__MODULE__{
          id: non_neg_integer,
          name: String.t() | nil,
          website: String.t() | nil,
          client_id: String.t(),
          client_secret: String.t(),
          client_secret_expires_at: non_neg_integer | nil,
          scopes: [String.t()] | nil,
          redirect_uris: [String.t()] | nil,
          redirect_uri: String.t() | nil
        }

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :name,
    :website,
    :client_id,
    :client_secret,
    :client_secret_expires_at,
    :scopes,
    :redirect_uris,
    :redirect_uri
  ]

  @doc """
  Register a new OAuth client app on the target instance

  ## Parameters

    * `client_name` - name of your application
    * `redirect_uris` - where the user should be redirected after authorization,
      default: `urn:ietf:wg:oauth:2.0:oob` (no redirect)
    * `scopes` - scope list, see the scope section for more details,
      default: `read`
    * `website` - URL to the homepage of your app, default: `nil`
    * `options` - option list

  ## Scopes

    * `read` - read data
    * `write` - post statuses and upload media for statuses
    * `follow` - follow, unfollow, block, unblock

  Multiple scopes can be requested during the authorization phase with the
  `scope` query param

  ## Options

    * `save?` - persists your application information to a file, so, you can use
      them later. default: `false`
    * `api_base_url` - specifies if you want to register an application on a
      different instance. default: `https://mastodon.social`

  ## Examples

      iex> Hunter.Application.create_app("hunter", "urn:ietf:wg:oauth:2.0:oob", ["read", "write", "follow"], nil, [save?: true, api_base_url: "https://example.com"])
      %Hunter.Application{client_id: "1234567890",
       client_secret: "1234567890",
       id: 1234}

  """
  @spec create_app(String.t(), String.t(), [String.t()], nil | String.t(), Keyword.t()) ::
          Hunter.Application.t()
  def create_app(
        client_name,
        redirect_uris \\ "urn:ietf:wg:oauth:2.0:oob",
        scopes \\ ["read"],
        website \\ nil,
        options \\ []
      ) do
    {save?, options} = Keyword.pop(options, :save?, false)
    base_url = Keyword.get(options, :api_base_url, Config.api_base_url())

    app = Config.hunter_api().create_app(client_name, redirect_uris, scopes, website, base_url)

    if save?, do: save_credentials(client_name, app)

    app
  end

  @doc """
  Load persisted application's credentials

  ## Parameters

    * `name` - application name

  """
  @spec load_credentials(String.t()) :: Hunter.Application.t() | no_return
  def load_credentials(name) do
    Hunter.Config.home()
    |> Path.join("apps/#{name}.json")
    |> File.read!()
    |> Poison.decode!(as: %Hunter.Application{})
  end

  defp save_credentials(name, app) do
    home = Path.join(Hunter.Config.home(), "apps")

    unless File.exists?(home), do: File.mkdir_p!(home)

    File.write!("#{home}/#{name}.json", Poison.encode!(app))
  end
end
