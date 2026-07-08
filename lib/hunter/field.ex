defmodule Hunter.Field do
  @moduledoc """
  Field entity

  A profile field as a name-value pair with optional verification, part of
  `Hunter.Account`

  ## Fields

    * `name` - the key of a given field's key-value pair
    * `value` - the value associated with the `name` key; this will contain HTML
    * `verified_at` - timestamp of when the server verified a URL value for a
      rel="me" link, `nil` if not verified

  """

  @type t :: %__MODULE__{
          name: String.t(),
          value: String.t(),
          verified_at: String.t() | nil
        }

  @derive [Poison.Encoder]
  defstruct [:name, :value, :verified_at]
end
