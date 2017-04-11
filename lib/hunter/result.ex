defmodule Hunter.Result do
  @moduledoc """
  Result entity

  ## Fields

    * `accounts` - list of matched `Hunter.Account`
    * `statuses` - list of matched `Hunter.Status`
    * `hashtags` - list of matched hashtags, as strings

  """
  @hunter_api Application.get_env(:hunter, :hunter_api)

  @type t :: %__MODULE__{
    accounts: [Hunter.Account.t],
    statuses: [Hunter.Status.t],
    hashtags: [String.t]
  }

  @derive [Poison.Encoder]
  defstruct accounts: [],
            statuses: [],
            hashtags: []

  @doc """
  Search for content

  ## Parameters

    * `conn` - Connection credentials
    * `q` - the search query
    * `options` - option list

  ## Options

    * `resolve` - Whether to resolve non-local accounts

  """
  @spec search(Hunter.Client.t, String.t, Keyword.t) :: Hunter.Result.t
  def search(conn, query, options \\ []) do
    @hunter_api.search(conn, query, options)
  end
end
