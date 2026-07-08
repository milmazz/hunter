defmodule Hunter.AnnualReport do
  @moduledoc """
  AnnualReport entity

  A yearly summary of account activity ("Wrapstodon")

  ## Fields

    * `year` - the year this report is about
    * `data` - the raw report data as a map; its shape depends on
      `schema_version`
    * `schema_version` - which schema version defines how to interpret `data`
    * `share_url` - a link to a shareable version of the report, if any
    * `account_id` - the ID of the account this report is about

  """

  @type t :: %__MODULE__{
          year: non_neg_integer,
          data: map,
          schema_version: non_neg_integer,
          share_url: String.t() | nil,
          account_id: String.t()
        }

  @derive [Poison.Encoder]
  defstruct [:year, :data, :schema_version, :share_url, :account_id]
end
