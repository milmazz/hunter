defmodule Hunter.Client do
  @moduledoc """
  Defines a `Hunter` client
  """

  @type t :: %__MODULE__{
          base_url: String.t(),
          access_token: String.t()
        }

  @derive [Poison.Encoder]
  defstruct [:base_url, :access_token]
end
