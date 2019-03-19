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
  alias Hunter.Config

  @type t :: %__MODULE__{
          id: non_neg_integer,
          client_id: String.t(),
          client_secret: String.t()
        }

  @derive [Poison.Encoder]
  defstruct [:id, :client_id, :client_secret]

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
  @spec create_app(String.t(), String.t(), [String.t()], String.t(), Keyword.t()) ::
          Hunter.Application.t() | no_return
  def create_app(
        client_name,
        redirect_uris \\ "urn:ietf:wg:oauth:2.0:oob",
        scopes \\ ["read"],
        website \\ nil,
        options \\ []
      ) do
    save? = Keyword.get(options, :save?, false)
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
  @spec load_credentials(String.t()) :: Hunter.Application.t()
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
