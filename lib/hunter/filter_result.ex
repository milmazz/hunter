defmodule Hunter.FilterResult do
  @moduledoc """
  FilterResult entity

  A filter whose keywords matched a given status, part of `Hunter.Status`

  ## Fields

    * `filter` - the `Hunter.Filter` that was matched
    * `keyword_matches` - the keywords within the filter that were matched,
      if any
    * `status_matches` - the status IDs within the filter that were matched,
      if any

  """

  @type t :: %__MODULE__{
          filter: Hunter.Filter.t(),
          keyword_matches: [String.t()] | nil,
          status_matches: [String.t()] | nil
        }

  @derive [Poison.Encoder]
  defstruct [:filter, :keyword_matches, :status_matches]
end
