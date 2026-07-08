defmodule Hunter.FilterKeyword do
  @moduledoc """
  FilterKeyword entity

  A keyword that, if matched, should cause the filter action to be taken,
  part of `Hunter.Filter`

  ## Fields

    * `id` - the ID of the filter keyword
    * `keyword` - the phrase to be matched against
    * `whole_word` - whether the keyword should consider word boundaries

  """

  @type t :: %__MODULE__{
          id: String.t(),
          keyword: String.t(),
          whole_word: boolean
        }

  @derive [Poison.Encoder]
  defstruct [:id, :keyword, :whole_word]
end
