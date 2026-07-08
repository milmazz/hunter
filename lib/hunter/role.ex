defmodule Hunter.Role do
  @moduledoc """
  Role entity

  A custom user role that grants permissions, shown on `Hunter.Account` as a
  partial (only roles with a visible badge are returned)

  ## Fields

    * `id` - the ID of the role
    * `name` - the name of the role
    * `color` - the hex code assigned to this role, empty when no color

  """

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          color: String.t()
        }

  @derive [Poison.Encoder]
  defstruct [:id, :name, :color]
end
