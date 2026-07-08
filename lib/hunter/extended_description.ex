defmodule Hunter.ExtendedDescription do
  @moduledoc """
  ExtendedDescription entity

  An extended description of the instance, to be shown on its about page

  ## Fields

    * `updated_at` - when the content was last updated
    * `content` - the rendered HTML content of the extended description

  """

  @type t :: %__MODULE__{
          updated_at: String.t(),
          content: String.t()
        }

  @derive [Poison.Encoder]
  defstruct [:updated_at, :content]
end
