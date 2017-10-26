defmodule Hunter.Tag do
  @moduledoc """
  Tag entity

  ## Fields

    * `name` - The hashtag, not including the preceding `#`
    * `url` - The URL of the hashtag

  """

  @type t :: %__MODULE__{
          name: String.t(),
          url: String.t()
        }

  @derive [Poison.Encoder]
  defstruct [:name, :url]
end
