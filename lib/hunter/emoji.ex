defmodule Hunter.Emoji do
  @moduledoc """
  Emoji entity
  """
  @type t :: %__MODULE__{
          shortcode: String.t(),
          static_url: String.t(),
          url: String.t(),
          visible_in_picker: boolean()
        }

  @derive [Poison.Encoder]
  defstruct [:shortcode, :static_url, :url, :visible_in_picker]
end
