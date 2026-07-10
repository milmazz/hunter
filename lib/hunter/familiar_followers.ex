defmodule Hunter.FamiliarFollowers do
  @moduledoc """
  FamiliarFollowers entity

  Accounts you follow that also follow a given account

  ## Fields

    * `id` - the account id these familiar followers relate to
    * `accounts` - accounts you follow that also follow that account

  """

  @type t :: %__MODULE__{
          id: String.t(),
          accounts: [Hunter.Account.t()]
        }

  @derive [Poison.Encoder]
  defstruct [:id, :accounts]
end
