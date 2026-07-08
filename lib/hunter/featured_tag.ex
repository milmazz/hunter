defmodule Hunter.FeaturedTag do
  @moduledoc """
  FeaturedTag entity

  A hashtag that is featured on a profile

  ## Fields

    * `id` - the ID of the featured tag
    * `name` - the name of the hashtag being featured, without the `#`
    * `url` - link to all statuses by the user that contain the hashtag
    * `statuses_count` - number of authored statuses containing the hashtag
    * `last_status_at` - date of the last authored status containing the
      hashtag, if any

  """

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          url: String.t(),
          statuses_count: non_neg_integer,
          last_status_at: String.t() | nil
        }

  @derive [Poison.Encoder]
  defstruct [:id, :name, :url, :statuses_count, :last_status_at]
end
