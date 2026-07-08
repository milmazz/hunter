defmodule Hunter.Collection.Item do
  @moduledoc """
  Collection item entity

  An account featured in a `Hunter.Collection`

  ## Fields

    * `id` - the ID of the collection item
    * `account_id` - the ID of the account this item represents
    * `state` - consent state of the item, one of: `pending`, `accepted`,
      `rejected`, `revoked`
    * `created_at` - when the item was added to the collection

  """

  @type t :: %__MODULE__{
          id: String.t(),
          account_id: String.t() | nil,
          state: String.t(),
          created_at: String.t()
        }

  @derive [Poison.Encoder]
  defstruct [:id, :account_id, :state, :created_at]
end
