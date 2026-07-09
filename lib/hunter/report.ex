defmodule Hunter.Report do
  @moduledoc """
  Report entity

  This module defines a `Hunter.Report` struct.

  ## Fields

    * `id` - id of the report
    * `action_taken` - action taken in response to the report

  """

  @type t :: %__MODULE__{
          id: String.t(),
          action_taken: String.t()
        }

  @derive [Poison.Encoder]
  defstruct [:id, :action_taken]
end
