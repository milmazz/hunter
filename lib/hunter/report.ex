defmodule Hunter.Report do
  @moduledoc """
  Report entity

  This module defines a `Hunter.Report` struct and the main functions
  for working with Reports.

  ## Fields

    * `id` - The ID of the report
    * `action_taken` - The action taken in response to the report

  """
  @hunter_api Application.get_env(:hunter, :hunter_api)

  @type t :: %__MODULE__{
    id: non_neg_integer,
    action_taken: String.t
  }

  @derive [Poison.Encoder]
  defstruct [:id, :action_taken]

  @doc """
  Retrieve a user's reports

  ## Parameters

    * `conn` - connection credentials

  """
  @spec reports(Hunter.Client.t) :: [Hunter.Report.t]
  def reports(conn) do
    @hunter_api.reports(conn)
  end

  @doc """
  Report a user

  ## Parameters

    * `conn` - connection credentials
    * `account_id` - the ID of the account to report
    * `status_ids` - the IDs of statuses to report
    * `comment` - a comment to associate with the report

  """
  @spec report(Hunter.Client.t, non_neg_integer, [non_neg_integer], String.t) :: Hunter.Report.t
  def report(conn, account_id, status_ids, comment) do
    @hunter_api.report(conn, account_id, status_ids, comment)
  end
end
