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
  alias Hunter.Api.HTTPClient

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

  @doc """
  Retrieve a poll

  ## Parameters

    * `conn` - connection credentials
    * `id` - poll identifier

  """
  @spec poll(Hunter.Client.t(), String.t() | non_neg_integer) :: Hunter.Poll.t()
  def poll(conn, id) do
    HTTPClient.poll(conn, id)
  end

  @doc """
  Vote on one or more options in a poll

  ## Parameters

    * `conn` - connection credentials
    * `id` - poll identifier
    * `choices` - list of option indices to vote for (zero-based); multiple
      choices are only allowed on multiple-choice polls

  """
  @spec vote(Hunter.Client.t(), String.t() | non_neg_integer, [non_neg_integer]) ::
          Hunter.Poll.t()
  def vote(conn, id, choices) do
    HTTPClient.vote(conn, id, choices)
  end
end
