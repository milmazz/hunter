defmodule Hunter.Marker do
  @moduledoc """
  Marker entity

  The last read position within a user's timeline; the markers endpoint
  returns a map with `home` and/or `notifications` keys, each holding
  one marker

  ## Fields

    * `last_read_id` - the ID of the most recently viewed entity
    * `version` - incrementing counter, used for locking to prevent write
      conflicts
    * `updated_at` - when the marker was set

  """

  @type t :: %__MODULE__{
          last_read_id: String.t(),
          version: non_neg_integer,
          updated_at: String.t()
        }

  @derive [Poison.Encoder]
  defstruct [:last_read_id, :version, :updated_at]
end
