defmodule Hunter.EventStream do
  @moduledoc """
  Event stream is a simple stream of text data encoded using UTF-8

  Messages in the event stream are separated by a pair of newline characters. A
  colon as the first character of a line is in essence a comment, and is ignored.

  ## Fields

  * `id` - event id
  * `event` - the event's type
  * `data` - data field for the message, this data is JSON-encoded
  * `retry` - re-connection time to use when attempting to send the event.

  See: https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format

  """

  @type t :: %__MODULE__{
      id: String.t,
      event: String.t,
      data: String.t,
      retry: non_neg_integer
  }

  defstruct [:id, :event, :data, :retry]
end
