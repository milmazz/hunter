defmodule Hunter.Context do
  @moduledoc """
  Context entity

  ## Fields

    * `ancestors` - The ancestors of the status in the conversation, as a list of Statuses
    * `descendants` - The descendants of the status in the conversation, as a list of Statuses

  """

  @type t :: %__MODULE__{
          ancestors: [Hunter.Status.t()],
          descendants: [Hunter.Status.t()]
        }

  @derive [Poison.Encoder]
  defstruct [:ancestors, :descendants]
end
