defmodule Hunter.Poll.Option do
  @moduledoc """
  Poll option entity

  A possible answer of a `Hunter.Poll`

  ## Fields

    * `title` - the text value of the poll option
    * `votes_count` - the number of received votes for this option, `nil`
      until the poll results are published

  """

  @type t :: %__MODULE__{
          title: String.t(),
          votes_count: non_neg_integer | nil
        }

  @derive [Poison.Encoder]
  defstruct [:title, :votes_count]
end
