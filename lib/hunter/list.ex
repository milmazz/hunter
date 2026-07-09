defmodule Hunter.List do
  @moduledoc """
  List entity

  A list of some users that the authenticated user follows

  ## Fields

    * `id` - the ID of the list
    * `title` - the user-defined title of the list
    * `replies_policy` - which replies should be shown in the list, one of:
      `followed`, `list`, `none`
    * `exclusive` - whether members of the list are removed from the home
      timeline

  """

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          replies_policy: String.t(),
          exclusive: boolean | nil
        }

  @derive [Poison.Encoder]
  defstruct [:id, :title, :replies_policy, :exclusive]
end
