defmodule Hunter.Tag do
  @moduledoc """
  Tag entity

  ## Fields

    * `id` - Database ID of the hashtag, useful for Admin API URLs
    * `name` - The hashtag, not including the preceding `#`
    * `url` - The URL of the hashtag
    * `history` - usage statistics for given days (last 7), a list of maps
      with `day`, `uses` and `accounts` keys
    * `following` - whether the current authorized user is following this tag
    * `featuring` - whether the current authorized user is featuring this tag
      on their profile

  """

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t(),
          url: String.t(),
          history: [map] | nil,
          following: boolean | nil,
          featuring: boolean | nil
        }

  @derive [Poison.Encoder]
  defstruct [:id, :name, :url, :history, :following, :featuring]
end
