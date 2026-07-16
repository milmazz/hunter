defmodule Hunter.Streaming.Event do
  @moduledoc """
  A parsed event from Mastodon's streaming WebSocket

  ## Fields

    * `streams` - the stream names this event was delivered on
    * `type` - the event type, e.g. `"update"`, `"notification"`, `"delete"`
    * `payload` - the decoded payload: an entity struct for known types, the
      bare id string for `delete`/`announcement.delete`, `nil` for
      payload-less events, or the raw payload for unknown types

  """

  alias Hunter.Api.Transformer

  @type t :: %__MODULE__{
          streams: [String.t()],
          type: String.t(),
          payload: term
        }

  defstruct [:streams, :type, :payload]

  @doc """
  Parses a raw WebSocket text frame into an event.

  Mastodon frames look like
  `{"stream": ["user"], "event": "update", "payload": "<JSON string>"}` —
  the payload is itself JSON-encoded, except for `delete` (a bare id) and
  payload-less events. Unknown event types are passed through with the raw
  payload so new server-side types keep flowing.
  """
  @spec parse(binary) :: {:ok, t} | {:error, term}
  def parse(frame) when is_binary(frame) do
    case Poison.decode(frame) do
      {:ok, %{"event" => type} = decoded} ->
        payload = decode_payload(type, Map.get(decoded, "payload"))
        {:ok, %__MODULE__{streams: Map.get(decoded, "stream", []), type: type, payload: payload}}

      {:ok, _other} ->
        {:error, :missing_event}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    exception -> {:error, exception}
  end

  defp decode_payload(_type, nil), do: nil

  defp decode_payload(type, payload) when type in ["update", "status.update"],
    do: Transformer.transform(payload, :status)

  defp decode_payload("notification", payload), do: Transformer.transform(payload, :notification)

  defp decode_payload("conversation", payload), do: Transformer.transform(payload, :conversation)

  defp decode_payload("announcement", payload), do: Transformer.transform(payload, :announcement)

  defp decode_payload("announcement.reaction", payload),
    do: Transformer.transform(payload, :announcement_reaction)

  defp decode_payload(type, payload) when type in ["delete", "announcement.delete"], do: payload

  defp decode_payload(_unknown, payload), do: payload
end
