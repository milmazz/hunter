defmodule Hunter.PrivacyPolicy do
  @moduledoc """
  PrivacyPolicy entity

  The privacy policy of the instance

  ## Fields

    * `updated_at` - when the content was last updated
    * `content` - the rendered HTML content of the privacy policy

  """

  @type t :: %__MODULE__{
          updated_at: String.t(),
          content: String.t()
        }

  @derive [Poison.Encoder]
  defstruct [:updated_at, :content]
end
