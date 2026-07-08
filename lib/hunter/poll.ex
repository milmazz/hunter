defmodule Hunter.Poll do
  @moduledoc """
  Poll entity

  A poll attached to a `Hunter.Status`

  ## Fields

    * `id` - the ID of the poll
    * `expires_at` - when the poll ends, if it has an end
    * `expired` - whether the poll is currently expired
    * `multiple` - whether the poll allows multiple-choice answers
    * `votes_count` - how many votes have been received
    * `voters_count` - how many unique accounts have voted, `nil` when the
      poll is not multiple-choice
    * `options` - list of `Hunter.Poll.Option`, the possible answers
    * `emojis` - list of `Hunter.Emoji`, custom emoji used in the options
    * `voted` - whether the authenticated user has voted (only with user token)
    * `own_votes` - which options the authenticated user chose, by index
      (only with user token)

  """

  @type t :: %__MODULE__{
          id: String.t(),
          expires_at: String.t() | nil,
          expired: boolean,
          multiple: boolean,
          votes_count: non_neg_integer,
          voters_count: non_neg_integer | nil,
          options: [Hunter.Poll.Option.t()],
          emojis: [Hunter.Emoji.t()],
          voted: boolean | nil,
          own_votes: [non_neg_integer] | nil
        }

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :expires_at,
    :expired,
    :multiple,
    :votes_count,
    :voters_count,
    :options,
    :emojis,
    :voted,
    :own_votes
  ]

  defmodule Option do
    @moduledoc """
    Poll option entity

    A possible answer of a `Hunter.Poll`

    ## Fields

      * `title` - the text value of the poll option
      * `votes_count` - the number of received votes for this option, `nil`
        until the poll results are published

    """

    @type t :: %__MODULE__{
            title: String.t(),
            votes_count: non_neg_integer | nil
          }

    @derive [Poison.Encoder]
    defstruct [:title, :votes_count]
  end
end
