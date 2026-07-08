defmodule Hunter.Conversation do
  @moduledoc """
  Conversation entity

  A conversation with "direct message" visibility

  ## Fields

    * `id` - the ID of the conversation
    * `unread` - whether the conversation is currently marked as unread
    * `accounts` - list of `Hunter.Account`, participants in the conversation
    * `last_status` - the last `Hunter.Status` in the conversation, if any

  """

  @type t :: %__MODULE__{
          id: String.t(),
          unread: boolean,
          accounts: [Hunter.Account.t()],
          last_status: Hunter.Status.t() | nil
        }

  @derive [Poison.Encoder]
  defstruct [:id, :unread, :accounts, :last_status]
end
