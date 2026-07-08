defmodule Hunter.Quote do
  @moduledoc """
  Quote entity

  Information about a status quoting another status, part of `Hunter.Status`.

  Covers both variants Mastodon returns: a full quote carries the quoted
  status in `quoted_status`, while the shallow variant (used for nested
  quotes) only carries `quoted_status_id`.

  ## Fields

    * `state` - state of the quote, one of: `pending`, `accepted`, `rejected`,
      `revoked`, `deleted`, `unauthorized`, `blocked_account`,
      `blocked_domain`, `muted_account`; unknown values should be treated
      as `unauthorized`
    * `quoted_status` - the `Hunter.Status` being quoted, `nil` unless the
      state allows showing it
    * `quoted_status_id` - the ID of the status being quoted (shallow variant)

  """

  @type t :: %__MODULE__{
          state: String.t(),
          quoted_status: Hunter.Status.t() | nil,
          quoted_status_id: String.t() | nil
        }

  @derive [Poison.Encoder]
  defstruct [:state, :quoted_status, :quoted_status_id]
end
