defmodule Hunter.Card.Author do
  @moduledoc """
  Card author entity

  A fediverse author of the resource a `Hunter.Card` previews

  ## Fields

    * `name` - the original resource author's name
    * `url` - a link to the author's website
    * `account` - the author's `Hunter.Account`, if known to the instance

  """

  @type t :: %__MODULE__{
          name: String.t(),
          url: String.t(),
          account: Hunter.Account.t() | nil
        }

  @derive [Poison.Encoder]
  defstruct [:name, :url, :account]
end
