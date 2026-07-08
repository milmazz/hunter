defmodule Hunter.FilterStatus do
  @moduledoc """
  FilterStatus entity

  A status ID that, if matched, should cause the filter action to be taken,
  part of `Hunter.Filter`

  ## Fields

    * `id` - the ID of the filter status
    * `status_id` - the ID of the filtered status

  """

  @type t :: %__MODULE__{
          id: String.t(),
          status_id: String.t()
        }

  @derive [Poison.Encoder]
  defstruct [:id, :status_id]
end
