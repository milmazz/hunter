defmodule Hunter.StreamingServer.Handler do
  @moduledoc """
  Scriptable WebSock handler for `Hunter.StreamingServer`.

  Tests drive the socket by messaging the handler pid announced via
  `{:ws_connected, pid}`:

    * `{:push_text, binary}` - send a text frame to the client
    * `:ping_client` - send a ping frame
    * `{:close, code}` - close the socket with `code`

  """

  @behaviour WebSock

  @impl WebSock
  def init(%{test_pid: test_pid} = state) do
    send(test_pid, {:ws_connected, self()})
    {:ok, state}
  end

  @impl WebSock
  def handle_in({data, [opcode: :text]}, state) do
    send(state.test_pid, {:ws_frame, Poison.decode!(data)})
    {:ok, state}
  end

  @impl WebSock
  def handle_info({:push_text, data}, state), do: {:push, {:text, data}, state}
  def handle_info(:ping_client, state), do: {:push, {:ping, "hb"}, state}
  def handle_info({:close, code}, state), do: {:stop, :normal, code, state}

  @impl WebSock
  def handle_control({data, [opcode: :pong]}, state) do
    send(state.test_pid, {:ws_pong, data})
    {:ok, state}
  end

  def handle_control(_frame, state), do: {:ok, state}

  @impl WebSock
  def terminate(_reason, _state), do: :ok
end
