defmodule Hunter.Preferences do
  @moduledoc """
  Preferences entity

  The user's preferences for common client behaviors; the field names mirror
  the colon-separated keys of the API response, so they must be accessed
  with quoted-atom syntax, e.g. `preferences."posting:default:visibility"`

  ## Fields

    * `posting:default:visibility` - default visibility for new statuses,
      one of: `public`, `unlisted`, `private`, `direct`
    * `posting:default:sensitive` - whether new statuses are marked sensitive
      by default
    * `posting:default:language` - default language for new statuses, if set
    * `reading:expand:media` - whether media attachments should be
      automatically displayed or blurred/hidden, one of: `default`,
      `show_all`, `hide_all`
    * `reading:expand:spoilers` - whether content-warned statuses should be
      expanded automatically

  """

  @type t :: %__MODULE__{
          :"posting:default:visibility" => String.t(),
          :"posting:default:sensitive" => boolean,
          :"posting:default:language" => String.t() | nil,
          :"reading:expand:media" => String.t(),
          :"reading:expand:spoilers" => boolean
        }

  @derive [Poison.Encoder]
  defstruct [
    :"posting:default:visibility",
    :"posting:default:sensitive",
    :"posting:default:language",
    :"reading:expand:media",
    :"reading:expand:spoilers"
  ]
end
