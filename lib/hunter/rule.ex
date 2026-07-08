defmodule Hunter.Rule do
  @moduledoc """
  Rule entity

  A rule that server users should follow

  ## Fields

    * `id` - the ID of the rule
    * `text` - the rule to be followed
    * `hint` - longer-form description of the rule

  """

  @type t :: %__MODULE__{
          id: String.t(),
          text: String.t(),
          hint: String.t() | nil
        }

  @derive [Poison.Encoder]
  defstruct [:id, :text, :hint]
end
