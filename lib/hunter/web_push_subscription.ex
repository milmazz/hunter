defmodule Hunter.WebPushSubscription do
  @moduledoc """
  WebPushSubscription entity

  A subscription to the Web Push API

  ## Fields

    * `id` - the ID of the Web Push subscription in the database
    * `endpoint` - where push alerts will be sent to
    * `standard` - whether the subscription uses standardized web push
      (RFC 8030, 8291 and 8292) or legacy web push drafts
    * `server_key` - the streaming server's VAPID key
    * `alerts` - map of notification types to booleans, which alerts should
      be delivered to the endpoint (`mention`, `status`, `reblog`, `follow`,
      `follow_request`, `favourite`, `poll`, `update`, `admin.sign_up`,
      `admin.report`)

  """

  @type t :: %__MODULE__{
          id: String.t(),
          endpoint: String.t(),
          standard: boolean,
          server_key: String.t(),
          alerts: map
        }

  @derive [Poison.Encoder]
  defstruct [:id, :endpoint, :standard, :server_key, :alerts]
end
