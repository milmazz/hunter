defmodule Hunter.Context do
  @moduledoc """
  Context entity

  ## Fields

    * `ancestors` - The ancestors of the status in the conversation, as a list of Statuses
    * `descendants` - The descendants of the status in the conversation, as a list of Statuses

  """
  defstruct [:ancestors, :descendants]
end
