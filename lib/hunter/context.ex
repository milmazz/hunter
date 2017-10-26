defmodule Hunter.Context do
  @moduledoc """
  Context entity

  ## Fields

    * `ancestors` - The ancestors of the status in the conversation, as a list of Statuses
    * `descendants` - The descendants of the status in the conversation, as a list of Statuses

  """
  @hunter_api Hunter.Config.hunter_api()

  @type t :: %__MODULE__{
          ancestors: [Hunter.Status.t()],
          descendants: [Hunter.Status.t()]
        }

  @derive [Poison.Encoder]
  defstruct [:ancestors, :descendants]

  @doc """
  Retrieve status context

  ## Parameters

    * `conn` - connection credentials
    * `id` - status identifier

  """
  @spec status_context(Hunter.Client.t(), non_neg_integer) :: Hunter.Context.t()
  def status_context(conn, id) do
    @hunter_api.status_context(conn, id)
  end
end
