defmodule Hunter.Client do
  @moduledoc """
  Defines a `Hunter` client
  """

  alias Hunter.Config

  @type t :: %__MODULE__{
          base_url: String.t(),
          bearer_token: String.t()
        }

  @derive [Poison.Encoder]
  defstruct [:base_url, :bearer_token]

  @doc """
  Initializes a client

  ## Options

    * `base_url` - URL of the instance you want to connect to
    * `bearer_token` - [String] OAuth access token for your authenticated user

  """
  @spec new(Keyword.t()) :: Hunter.Client.t()
  def new(options \\ []) do
    struct(Hunter.Client, options)
  end

  @doc """
  User agent of the client
  """
  @spec user_agent() :: String.t()
  def user_agent do
    "Hunter.Elixir/#{Hunter.version()}"
  end

  @doc """
  Retrieve access token

  ## Parameters

    * `app` - application details, see: `Hunter.Application.create_app/5` for more details.
    * `username` - your account's email
    * `password` - your password
    * `base_url` - API base url, default: `https://mastodon.social`

  """
  @spec log_in(Hunter.Application.t(), String.t(), String.t(), String.t()) :: Hunter.Client.t()
  def log_in(app, username, password, base_url \\ nil) do
    base_url = base_url || Config.api_base_url()
    Config.hunter_api().log_in(app, username, password, base_url)
  end
end
