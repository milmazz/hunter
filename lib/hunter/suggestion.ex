defmodule Hunter.Suggestion do
  @moduledoc """
  Suggestion entity

  A suggested account to follow, with a reason for the suggestion

  ## Fields

    * `source` - the reason this account is being suggested, one of: `staff`,
      `past_interactions`, `global` (deprecated since Mastodon 4.3 in favor
      of `sources`)
    * `sources` - reasons this account is being suggested, list of:
      `featured`, `most_followed`, `most_interactions`,
      `similar_to_recently_followed`, `friends_of_friends`
    * `account` - the `Hunter.Account` being recommended to follow

  """

  @type t :: %__MODULE__{
          source: String.t(),
          sources: [String.t()],
          account: Hunter.Account.t()
        }

  @derive [Poison.Encoder]
  defstruct [:source, :sources, :account]
end
