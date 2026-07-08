defmodule Hunter.TermsOfService do
  @moduledoc """
  TermsOfService entity

  The terms of service of the instance

  ## Fields

    * `effective_date` - the date these terms of service are/were coming
      into effect
    * `effective` - whether these terms of service are currently in effect
    * `content` - the rendered HTML content of the terms of service
    * `succeeded_by` - if there are newer terms of service, their effective
      date

  """

  @type t :: %__MODULE__{
          effective_date: String.t(),
          effective: boolean,
          content: String.t(),
          succeeded_by: String.t() | nil
        }

  @derive [Poison.Encoder]
  defstruct [:effective_date, :effective, :content, :succeeded_by]
end
