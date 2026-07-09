defmodule Hunter.Result do
  @moduledoc """
  Result entity

  ## Fields

    * `accounts` - list of matched `Hunter.Account`
    * `statuses` - list of matched `Hunter.Status`
    * `hashtags` - list of matched `Hunter.Tag`

  """

  @type t :: %__MODULE__{
          accounts: [Hunter.Account.t()],
          statuses: [Hunter.Status.t()],
          hashtags: [Hunter.Tag.t()]
        }

  @derive [Poison.Encoder]
  defstruct accounts: [],
            statuses: [],
            hashtags: []
end
