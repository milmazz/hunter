defmodule Hunter.Result do
  @moduledoc """
  Result entity

  ## Fields

    * `accounts` - list of matched `Hunter.Account`
    * `statuses` - list of matched `Hunter.Status`
    * `hashtags` - list of matched `Hunter.Tag`

  """
  alias Hunter.Api.HTTPClient

  @type t :: %__MODULE__{
          accounts: [Hunter.Account.t()],
          statuses: [Hunter.Status.t()],
          hashtags: [Hunter.Tag.t()]
        }

  @derive [Poison.Encoder]
  defstruct accounts: [],
            statuses: [],
            hashtags: []

  @doc """
  Search for content

  ## Parameters

    * `conn` - Connection credentials
    * `q` - the search query, if `q` is a URL Mastodon will attempt to fetch
      the provided account or status, it will do a local account and hashtag
      search
    * `options` - option list

  ## Options

    * `resolve` - Whether to resolve non-local accounts

  """
  @spec search(Hunter.Client.t(), String.t(), Keyword.t()) :: Hunter.Result.t()
  def search(conn, query, options \\ []) do
    HTTPClient.search(conn, query, options)
  end
end
