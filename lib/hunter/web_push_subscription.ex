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
  alias Hunter.Api.HTTPClient

  @type t :: %__MODULE__{
          id: String.t(),
          endpoint: String.t(),
          standard: boolean,
          server_key: String.t(),
          alerts: map
        }

  @derive [Poison.Encoder]
  defstruct [:id, :endpoint, :standard, :server_key, :alerts]

  @doc """
  Subscribe to Web Push notifications; each access token can have exactly
  one subscription, and creating a new one replaces it

  ## Parameters

    * `conn` - connection credentials
    * `subscription` - map with `endpoint` (where push alerts will be sent),
      `keys` (map with the `p256dh` public key and `auth` secret) and
      optionally `standard` (use standardized web push)
    * `data` - optional map with `alerts` (map of notification types to
      booleans) and `policy` (`all`, `followed`, `follower` or `none`)

  """
  @spec create_push_subscription(Hunter.Client.t(), map, map) :: Hunter.WebPushSubscription.t()
  def create_push_subscription(conn, subscription, data \\ %{}) do
    HTTPClient.create_push_subscription(conn, subscription, data)
  end

  @doc """
  Retrieve the Web Push subscription tied to the access token

  ## Parameters

    * `conn` - connection credentials

  """
  @spec push_subscription(Hunter.Client.t()) :: Hunter.WebPushSubscription.t()
  def push_subscription(conn) do
    HTTPClient.push_subscription(conn)
  end

  @doc """
  Update the `data` portion of the Web Push subscription (which alerts to
  receive and the delivery policy)

  ## Parameters

    * `conn` - connection credentials
    * `data` - map with `alerts` (map of notification types to booleans)
      and/or `policy` (`all`, `followed`, `follower` or `none`)

  """
  @spec update_push_subscription(Hunter.Client.t(), map) :: Hunter.WebPushSubscription.t()
  def update_push_subscription(conn, data) do
    HTTPClient.update_push_subscription(conn, data)
  end

  @doc """
  Remove the Web Push subscription tied to the access token

  ## Parameters

    * `conn` - connection credentials

  """
  @spec delete_push_subscription(Hunter.Client.t()) :: boolean
  def delete_push_subscription(conn) do
    HTTPClient.delete_push_subscription(conn)
  end
end
