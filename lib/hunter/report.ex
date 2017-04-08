defmodule Hunter.Report do
  @moduledoc """
  Report entity

  This module defines a `Hunter.Report` struct and the main functions
  for working with Reports.

  ## Fields

    * `id` - The ID of the report
    * `action_taken` - The action taken in response to the report

  """
  defstruct [:id, :action_taken]
end
