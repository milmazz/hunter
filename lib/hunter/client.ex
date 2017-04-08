defmodule Hunter.Client do
  @moduledoc """
  Defines a `Hunter` client
  """

  @type t :: %__MODULE__{
    base_url: URI.t,
    bearer_token: String.t

  }

  @derive [Poison.Encoder]
  defstruct [:base_url, :bearer_token]

  @doc """
  Initializes a client

  ## Options

    * `base_url` - URL of the instance you want to connect to
    * `bearer_token` - [String] OAuth access token for your authenticated user

  """
  @spec new(Keyword.t) :: Hunter.Client.t
  def new(options \\ []) do
    struct(Hunter.Client, options)
  end

  @doc """
  User agent of the client
  """
  @spec user_agent() :: String.t
  def user_agent do
    "Hunter.Elixir/#{Hunter.version}"
  end
end
