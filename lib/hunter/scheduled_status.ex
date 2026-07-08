defmodule Hunter.ScheduledStatus do
  @moduledoc """
  ScheduledStatus entity

  A status that will be published at a future scheduled date

  ## Fields

    * `id` - the ID of the scheduled status
    * `scheduled_at` - when the status will be published
    * `params` - the parameters that were used when scheduling the status,
      to be used when the status is posted (`text`, `visibility`, `poll`,
      `media_ids`, etc.)
    * `media_attachments` - list of `Hunter.Attachment` to be attached to
      the status when posted

  """

  @type t :: %__MODULE__{
          id: String.t(),
          scheduled_at: String.t(),
          params: map,
          media_attachments: [Hunter.Attachment.t()]
        }

  @derive [Poison.Encoder]
  defstruct [:id, :scheduled_at, :params, :media_attachments]
end
