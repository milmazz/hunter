defmodule Hunter.Mention do
  @moduledoc """
  Mention entity

  ## Fields

    * `url` - URL of user's profile (can be remote)
    * `username` - The username of the account
    * `acct` - Equals `username` for local users, includes `@domain` for remote ones
    * `id` - Account ID

  """
  @type t :: %__MODULE__{
    url: String.t,
    username: String.t,
    acct: String.t,
    id: non_neg_integer
  }

  @derive [Poison.Encoder]
  defstruct [:url, :username, :acct, :id]

end
