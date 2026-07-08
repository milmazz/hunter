defmodule Hunter.StatusSource do
  @moduledoc """
  StatusSource entity

  The raw, unformatted source of a `Hunter.Status`, as returned by the
  status source endpoint for use when editing

  ## Fields

    * `id` - the ID of the status
    * `text` - the plain-text source of the status
    * `spoiler_text` - the plain-text version of the spoiler warning

  """

  @type t :: %__MODULE__{
          id: String.t(),
          text: String.t(),
          spoiler_text: String.t()
        }

  @derive [Poison.Encoder]
  defstruct [:id, :text, :spoiler_text]
end
