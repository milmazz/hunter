# Streaming API Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Real-time timeline/notification events over Mastodon's multiplexed WebSocket endpoint (issue #3): `Hunter.Streaming` with `connect/subscribe/unsubscribe/close/health?`, parsed entity payloads delivered to a subscriber pid.

**Architecture:** One GenServer (`Hunter.Streaming.Connection`) owns the Mint conn + WebSocket state and performs the handshake synchronously in `init/1`; a pure module (`Hunter.Streaming.Event`) parses frames into entity structs via the existing `Hunter.Api.Transformer`. No supervision tree ships — callers supervise. No auto-reconnect in v1.

**Tech Stack:** Elixir 1.16+, `mint_web_socket ~> 1.0` (new runtime dep; mint already present via Req/Finch), Poison for JSON. Tests: scripted in-process WebSocket server on `bandit` + `websock_adapter` (test-only deps), `Req.Test` stubs for `health?`, real Mastodon streaming service in CI.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-07-10-streaming-design.md`. Branch: `streaming-3`.
- One module per file; folders mirror the module hierarchy (no nested `defmodule`).
- WebSocket only — no SSE endpoints, no auto-reconnect, no streaming-URL auto-discovery inside `connect/2`.
- Subscriber messages: `{:hunter_stream, connection_pid, %Hunter.Streaming.Event{}}` and `{:hunter_stream, connection_pid, {:closed, reason}}` with `reason :: {:remote, code} | {:error, term} | :local`; process exits `:normal` after any close. Server pings answered with pong, never surfaced.
- Stream names pass through verbatim — no client-side validation.
- Unknown event types are delivered with the raw payload, not dropped.
- `Hunter.EventStream` is deleted (breaking change, CHANGELOG under `## Unreleased`).
- Run `mix format` before every commit. Full gates: `mix test`, `mix format --check-formatted`, `mix credo`, `mix dialyzer`.
- Test output must be pristine (Bandit startup logs silenced with `startup_log: false`; expected `Logger.warning` output captured with `@tag :capture_log`).

### Where things live (orientation for every task)

- `lib/hunter/api/transformer.ex` — `Hunter.Api.Transformer.transform/2` clauses keyed by target atom; existing targets used here: `:status`, `:notification`, `:conversation`, `:announcement`. Entities decode with `Poison.decode!(body, as: struct)`.
- `lib/hunter/config.ex` — `Hunter.Config.req_options/0` returns the app-configured Req options keyword; the test env sets `plug: {Req.Test, Hunter.ReqStub}` (see `test/test_helper.exs`), so any Req call merging these options is stubbable with the `Hunter.ReqCase` helpers (`stub_request/1`, `respond_with/2-3`).
- `Hunter.Client` struct: exactly `%Hunter.Client{base_url: String.t(), access_token: String.t()}`. Tests construct it via `Hunter.new(base_url: ..., access_token: ...)`.
- Fixtures: `test/fixtures/status.json` (id `"103270115826048975"`), `notification.json` (type `"mention"`), `conversation.json` (id `"418450"`), `announcement.json` (id `"8"`, has a `reactions` array with `name: "bongoCat"`).
- `Hunter.Announcement.Reaction` struct exists at `lib/hunter/announcement/reaction.ex`.
- Integration tests: `test/integration/mastodon_test.exs` on `Hunter.IntegrationCase` (`@moduletag :integration`, excluded by default; setup_all provides `conn`/`conn2` against `HUNTER_BASE_URL` = `https://localhost:3000`, a self-signed-TLS nginx in front of Mastodon v4.3.8 — Req calls get `verify: :verify_none` via `req_options`, but `Hunter.Streaming.connect/2` talks Mint directly and needs its own `transport_opts: [verify: :verify_none]`).
- Mastodon WS frame shape: `{"stream": ["user"], "event": "update", "payload": "<JSON-encoded string>"}` — payload is double-encoded JSON except for `delete`/`announcement.delete` (plain id string) and payload-less events (`filters_changed`, `notifications_merged`).

---

### Task 1: `Hunter.Streaming.Event` + `:announcement_reaction` transformer clause

**Files:**
- Create: `lib/hunter/streaming/event.ex`
- Modify: `lib/hunter/api/transformer.ex`
- Test: `test/hunter/streaming/event_test.exs`

**Interfaces:**
- Consumes: `Hunter.Api.Transformer.transform/2` targets `:status`, `:notification`, `:conversation`, `:announcement`, and the new `:announcement_reaction`.
- Produces: `Hunter.Streaming.Event.t` = `%Hunter.Streaming.Event{streams: [String.t()], type: String.t(), payload: term}`; `Hunter.Streaming.Event.parse(binary) :: {:ok, t} | {:error, term}`. Tasks 3, 4, and 6 rely on both.

- [ ] **Step 1: Write the failing tests**

Create `test/hunter/streaming/event_test.exs`:

```elixir
defmodule Hunter.Streaming.EventTest do
  use ExUnit.Case, async: true

  alias Hunter.Streaming.Event

  test "parses an update into a Status" do
    assert {:ok, event} = Event.parse(frame("update", fixture("status")))

    assert %Event{streams: ["user"], type: "update"} = event
    assert %Hunter.Status{id: "103270115826048975", visibility: "public"} = event.payload
    assert %Hunter.Account{username: "milmazz"} = event.payload.account
  end

  test "parses a status.update into a Status" do
    assert {:ok, %Event{type: "status.update", payload: %Hunter.Status{}}} =
             Event.parse(frame("status.update", fixture("status")))
  end

  test "parses a notification into a Notification" do
    assert {:ok, %Event{type: "notification", payload: payload}} =
             Event.parse(frame("notification", fixture("notification")))

    assert %Hunter.Notification{type: "mention"} = payload
  end

  test "parses a conversation into a Conversation" do
    assert {:ok, %Event{payload: %Hunter.Conversation{id: "418450"}}} =
             Event.parse(frame("conversation", fixture("conversation")))
  end

  test "parses an announcement into an Announcement" do
    assert {:ok, %Event{payload: %Hunter.Announcement{id: "8"}}} =
             Event.parse(frame("announcement", fixture("announcement")))
  end

  test "parses an announcement.reaction into a Reaction" do
    payload = ~s({"name": "bongoCat", "count": 9, "announcement_id": "8"})

    assert {:ok, %Event{payload: %Hunter.Announcement.Reaction{name: "bongoCat", count: 9}}} =
             Event.parse(frame("announcement.reaction", payload))
  end

  test "delete and announcement.delete carry the id string" do
    assert {:ok, %Event{payload: "103270115826048975"}} =
             Event.parse(frame("delete", "103270115826048975"))

    assert {:ok, %Event{payload: "8"}} =
             Event.parse(frame("announcement.delete", "8"))
  end

  test "payload-less events have a nil payload" do
    assert {:ok, %Event{type: "filters_changed", payload: nil}} =
             Event.parse(~s({"stream": ["user"], "event": "filters_changed"}))

    assert {:ok, %Event{type: "notifications_merged", payload: nil}} =
             Event.parse(~s({"stream": ["user"], "event": "notifications_merged"}))
  end

  test "unknown event types pass the payload through undecoded" do
    assert {:ok, %Event{type: "brand.new", payload: "whatever"}} =
             Event.parse(frame("brand.new", "whatever"))
  end

  test "rejects malformed frames" do
    assert {:error, _} = Event.parse("not json")
    assert {:error, _} = Event.parse(~s({"stream": ["user"]}))
    assert {:error, _} = Event.parse(frame("update", "not a status"))
  end

  # Mastodon frames double-encode the payload: it is a JSON *string*.
  defp frame(type, payload) do
    Poison.encode!(%{"stream" => ["user"], "event" => type, "payload" => payload})
  end

  defp fixture(name) do
    [__DIR__, "..", "..", "fixtures", name <> ".json"]
    |> Path.join()
    |> Path.expand()
    |> File.read!()
  end
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `mix test test/hunter/streaming/event_test.exs`
Expected: FAIL — `Hunter.Streaming.Event` is not defined (compile error or UndefinedFunctionError).

- [ ] **Step 3: Create the Event module**

Create `lib/hunter/streaming/event.ex`:

```elixir
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
```

Note: `Transformer.transform/2` raises on invalid JSON (`Poison.decode!` inside); the `rescue` in `parse/1` converts that to `{:error, exception}` — this is what makes the `frame("update", "not a status")` test pass.

- [ ] **Step 4: Add the transformer clause**

In `lib/hunter/api/transformer.ex`, add directly after the `transform(body, :announcements)` clause:

```elixir
def transform(body, :announcement_reaction),
  do: Poison.decode!(body, as: %Hunter.Announcement.Reaction{})
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `mix test test/hunter/streaming/event_test.exs`
Expected: PASS (10 tests).

- [ ] **Step 6: Format, run the full suite, commit**

```bash
mix format
mix test
git add lib/hunter/streaming/event.ex lib/hunter/api/transformer.ex test/hunter/streaming/event_test.exs
git commit -m "feat: add Hunter.Streaming.Event frame parser"
```

---

### Task 2: `Hunter.Streaming.health?/2`

**Files:**
- Create: `lib/hunter/streaming.ex`
- Test: `test/hunter/streaming_test.exs`

**Interfaces:**
- Consumes: `Hunter.Config.req_options/0`, `Req.request/1`, `Hunter.Client` struct.
- Produces: `Hunter.Streaming.health?(Hunter.Client.t(), Keyword.t()) :: boolean` and the private `http_base_url/2` helper pattern. Task 3 adds `connect/2` and friends to this same file; Task 6 calls `health?/1` in integration.

- [ ] **Step 1: Write the failing tests**

Create `test/hunter/streaming_test.exs`:

```elixir
defmodule Hunter.StreamingTest do
  use Hunter.ReqCase, async: true

  @conn Hunter.new(base_url: "https://mastodon.example", access_token: "123456")

  describe "health?/2" do
    test "is true when the streaming server answers OK" do
      stub_request(fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/api/v1/streaming/health"
        respond_with(conn, "OK")
      end)

      assert Hunter.Streaming.health?(@conn)
    end

    test "is false on any other response" do
      stub_request(fn conn -> respond_with(conn, "no", 404) end)

      refute Hunter.Streaming.health?(@conn)
    end

    test "resolves a ws(s) url override to http(s)" do
      stub_request(fn conn ->
        assert conn.host == "streaming.example"
        respond_with(conn, "OK")
      end)

      assert Hunter.Streaming.health?(@conn, url: "wss://streaming.example")
    end
  end
end
```

Note: `respond_with(conn, "OK")` sends the body as-is (binary passthrough in `Hunter.ReqCase`), matching the real endpoint's plain-text response.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `mix test test/hunter/streaming_test.exs`
Expected: FAIL — `Hunter.Streaming` is not defined.

- [ ] **Step 3: Create the module**

Create `lib/hunter/streaming.ex`:

```elixir
defmodule Hunter.Streaming do
  @moduledoc """
  Real-time events over Mastodon's multiplexed streaming WebSocket.

  `connect/2` opens a connection process linked to the caller; parsed
  events arrive in the subscriber's mailbox as
  `{:hunter_stream, connection_pid, %Hunter.Streaming.Event{}}` and a
  single `{:hunter_stream, connection_pid, {:closed, reason}}` is sent
  when the socket closes. There is no automatic reconnection: supervise
  and restart the connection from the consuming application.

  Instances may serve streaming from a different host than the REST API;
  discover it via `Hunter.instance_info/1` under
  `configuration["urls"]["streaming"]` and pass it as the `:url` option.
  """

  alias Hunter.Config

  @doc """
  Checks the streaming server's health endpoint (Mastodon 2.5+).

  ## Parameters

    * `conn` - connection credentials
    * `opts` - `url:` overrides the streaming base URL (`ws://`/`wss://`
      accepted and mapped to `http://`/`https://`)

  Returns `true` only for a 200 response with an `OK` body; transport
  errors return `false`.
  """
  @spec health?(Hunter.Client.t(), Keyword.t()) :: boolean
  def health?(%Hunter.Client{} = conn, opts \\ []) do
    request =
      [
        method: :get,
        url: http_base_url(conn, opts) <> "/api/v1/streaming/health",
        decode_body: false,
        retry: false
      ] ++ Config.req_options()

    case Req.request(request) do
      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        String.trim(body) == "OK"

      _other ->
        false
    end
  end

  defp http_base_url(%Hunter.Client{base_url: base_url}, opts) do
    case Keyword.fetch(opts, :url) do
      {:ok, url} ->
        url
        |> String.replace_prefix("wss://", "https://")
        |> String.replace_prefix("ws://", "http://")
        |> String.trim_trailing("/")

      :error ->
        String.trim_trailing(base_url, "/")
    end
  end
end
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `mix test test/hunter/streaming_test.exs`
Expected: PASS (3 tests).

- [ ] **Step 5: Format, run the full suite, commit**

```bash
mix format
mix test
git add lib/hunter/streaming.ex test/hunter/streaming_test.exs
git commit -m "feat: add Hunter.Streaming.health?/2"
```

---

### Task 3: Connection handshake + event delivery (`connect/2`)

**Files:**
- Modify: `mix.exs` (deps)
- Create: `lib/hunter/streaming/connection.ex`
- Create: `test/support/streaming_server.ex`
- Create: `test/support/streaming_server/handler.ex`
- Modify: `lib/hunter/streaming.ex` (add `connect/2` + `ws_uri/2`)
- Test: `test/hunter/streaming_test.exs`

**Interfaces:**
- Consumes: `Hunter.Streaming.Event.parse/1` (Task 1), the `Hunter.Streaming` module file (Task 2).
- Produces: `Hunter.Streaming.connect(Hunter.Client.t(), Keyword.t()) :: {:ok, pid} | {:error, term}` with options `streams:` (list of `String.t()` or `{String.t(), Keyword.t()}`), `subscriber:` (pid, default `self()`), `url:` (ws(s) base URL override), `transport_opts:` (Mint transport options, e.g. `[verify: :verify_none]`); `Hunter.Streaming.Connection.start_link/1` taking `uri:, subscriber:, streams:, transport_opts:`; internal GenServer calls `{:control, type, stream, params}` and `:close` (Task 4 implements their public wrappers); the `Hunter.StreamingServer` test helper (`start/1` returning `{server_pid, port}`). Tasks 4 and 6 rely on all of this.

- [ ] **Step 1: Add the dependencies**

In `mix.exs`, change the deps list to:

```elixir
defp deps do
  [
    {:req, "~> 0.6"},
    {:poison, "~> 6.0"},
    {:mint_web_socket, "~> 1.0"},
    {:plug, "~> 1.16", only: :test},
    {:bandit, "~> 1.0", only: :test},
    {:websock_adapter, "~> 0.5", only: :test},
    {:ex_doc, "~> 0.40", only: :dev, runtime: false},
    {:dialyxir, "~> 1.0", only: :dev, runtime: false},
    {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
  ]
end
```

Run: `mix deps.get && mix compile`
Expected: deps resolve (mint is already in the lock via finch; mint_web_socket rides on it), clean compile.

- [ ] **Step 2: Create the scripted WebSocket test server**

Create `test/support/streaming_server.ex`:

```elixir
defmodule Hunter.StreamingServer do
  @moduledoc """
  In-process WebSocket server for streaming unit tests.

  `start/1` boots a Bandit listener on a random port whose plug reports the
  upgrade request to the test process and hands the socket to
  `Hunter.StreamingServer.Handler`. The test process receives:

    * `{:ws_request, path, query_params}` - the HTTP upgrade request
    * `{:ws_connected, handler_pid}` - the socket is up; message this pid
      to script the server (see the handler docs)
    * `{:ws_frame, decoded_json}` - each text frame the client sent
    * `{:ws_pong, data}` - the client answered a ping

  """

  @behaviour Plug

  import Plug.Conn

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, test_pid: test_pid) do
    conn = fetch_query_params(conn)
    send(test_pid, {:ws_request, conn.request_path, conn.query_params})

    WebSockAdapter.upgrade(conn, Hunter.StreamingServer.Handler, %{test_pid: test_pid}, [])
  end

  @doc """
  Starts the server under the test supervisor; returns `{pid, port}`.
  """
  def start(test_pid) do
    {:ok, server} =
      Bandit.start_link(
        plug: {__MODULE__, test_pid: test_pid},
        port: 0,
        ip: :loopback,
        startup_log: false
      )

    {:ok, {_ip, port}} = ThousandIsland.listener_info(server)
    {server, port}
  end
end
```

Create `test/support/streaming_server/handler.ex`:

```elixir
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
```

- [ ] **Step 3: Write the failing tests**

Append to `test/hunter/streaming_test.exs` (inside the outer module, after the `health?/2` describe block):

```elixir
  describe "connect/2" do
    test "handshakes with the access token and subscribes initial streams" do
      {_server, port} = Hunter.StreamingServer.start(self())

      assert {:ok, pid} = Hunter.Streaming.connect(client(), url: "ws://localhost:#{port}", streams: ["user", {"hashtag", tag: "elixir"}])

      assert_receive {:ws_request, "/api/v1/streaming", %{"access_token" => "123456"}}
      assert_receive {:ws_connected, _ws}
      assert_receive {:ws_frame, %{"type" => "subscribe", "stream" => "user"}}
      assert_receive {:ws_frame, %{"type" => "subscribe", "stream" => "hashtag", "tag" => "elixir"}}
      assert Process.alive?(pid)
    end

    test "delivers parsed events to the subscriber" do
      {_server, port} = Hunter.StreamingServer.start(self())
      {:ok, pid} = Hunter.Streaming.connect(client(), url: "ws://localhost:#{port}")
      assert_receive {:ws_connected, ws}

      status_json = File.read!(Path.expand(Path.join([__DIR__, "..", "fixtures", "status.json"])))
      frame = Poison.encode!(%{"stream" => ["user"], "event" => "update", "payload" => status_json})
      send(ws, {:push_text, frame})

      assert_receive {:hunter_stream, ^pid, %Hunter.Streaming.Event{type: "update", payload: %Hunter.Status{id: "103270115826048975"}}}
    end

    @tag :capture_log
    test "skips malformed frames and stays connected" do
      {_server, port} = Hunter.StreamingServer.start(self())
      {:ok, pid} = Hunter.Streaming.connect(client(), url: "ws://localhost:#{port}")
      assert_receive {:ws_connected, ws}

      send(ws, {:push_text, "not json"})
      send(ws, {:push_text, Poison.encode!(%{"stream" => ["user"], "event" => "update", "payload" => File.read!(Path.expand(Path.join([__DIR__, "..", "fixtures", "status.json"])))})})

      assert_receive {:hunter_stream, ^pid, %Hunter.Streaming.Event{type: "update"}}
      assert Process.alive?(pid)
    end

    test "returns an error when the endpoint refuses the upgrade" do
      # Nothing is listening on this port.
      assert {:error, _reason} = Hunter.Streaming.connect(client(), url: "ws://localhost:9")
    end
  end

  defp client, do: Hunter.new(base_url: "https://mastodon.example", access_token: "123456")
```

- [ ] **Step 4: Run the tests to verify they fail**

Run: `mix test test/hunter/streaming_test.exs`
Expected: the `health?/2` tests still PASS; the four `connect/2` tests FAIL with `UndefinedFunctionError` for `Hunter.Streaming.connect/2` (and `Hunter.StreamingServer` compiles from test/support).

- [ ] **Step 5: Create the Connection GenServer**

Create `lib/hunter/streaming/connection.ex`:

```elixir
defmodule Hunter.Streaming.Connection do
  # Owns the Mint conn + WebSocket state for one streaming connection.
  # Started via Hunter.Streaming.connect/2; not part of the public API.
  @moduledoc false

  use GenServer

  require Logger

  alias Hunter.Streaming.Event

  @handshake_timeout 15_000

  defstruct [:conn, :websocket, :ref, :subscriber]

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  @impl GenServer
  def init(opts) do
    uri = Keyword.fetch!(opts, :uri)
    subscriber = Keyword.fetch!(opts, :subscriber)
    streams = Keyword.get(opts, :streams, [])
    transport_opts = Keyword.get(opts, :transport_opts, [])

    {http_scheme, ws_scheme} = schemes(uri.scheme)
    path = uri.path <> "?" <> uri.query

    with {:ok, conn} <-
           Mint.HTTP.connect(http_scheme, uri.host, uri.port,
             protocols: [:http1],
             transport_opts: transport_opts
           ),
         {:ok, conn, ref} <- Mint.WebSocket.upgrade(ws_scheme, conn, path, []),
         {:ok, conn, status, headers} <- await_upgrade(conn, ref),
         {:ok, conn, websocket} <- Mint.WebSocket.new(conn, ref, status, headers) do
      state = %__MODULE__{conn: conn, websocket: websocket, ref: ref, subscriber: subscriber}

      case subscribe_initial(state, streams) do
        {:ok, state} -> {:ok, state}
        {:error, reason} -> {:stop, reason}
      end
    else
      {:error, reason} -> {:stop, reason}
      {:error, _conn, reason} -> {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call({:control, type, stream, params}, _from, state) do
    frame =
      params
      |> Map.new(fn {key, value} -> {to_string(key), to_string(value)} end)
      |> Map.merge(%{"type" => type, "stream" => stream})

    case send_frame(state, {:text, Poison.encode!(frame)}) do
      {:ok, state} -> {:reply, :ok, state}
      {:error, state, reason} -> stop_with(state, {:error, reason}, {:reply, :ok})
    end
  end

  def handle_call(:close, _from, state) do
    case send_frame(state, {:close, 1_000, ""}) do
      {:ok, state} -> stop_with(state, :local, {:reply, :ok})
      {:error, state, _reason} -> stop_with(state, :local, {:reply, :ok})
    end
  end

  @impl GenServer
  def handle_info(message, state) do
    case Mint.WebSocket.stream(state.conn, message) do
      {:ok, conn, entries} ->
        handle_entries(entries, %{state | conn: conn})

      {:error, conn, reason, _responses} ->
        stop_with(%{state | conn: conn}, {:error, reason}, :noreply)

      :unknown ->
        {:noreply, state}
    end
  end

  defp handle_entries(entries, state) do
    frames =
      for {:data, ref, data} <- entries, ref == state.ref do
        data
      end

    Enum.reduce_while(frames, {:noreply, state}, fn data, {:noreply, state} ->
      case decode_frames(state, data) do
        {:noreply, state} -> {:cont, {:noreply, state}}
        stop -> {:halt, stop}
      end
    end)
  end

  defp decode_frames(state, data) do
    case Mint.WebSocket.decode(state.websocket, data) do
      {:ok, websocket, frames} ->
        dispatch_frames(frames, %{state | websocket: websocket})

      {:error, websocket, reason} ->
        Logger.warning("Hunter.Streaming: undecodable data: #{inspect(reason)}")
        {:noreply, %{state | websocket: websocket}}
    end
  end

  defp dispatch_frames([], state), do: {:noreply, state}

  defp dispatch_frames([{:text, text} | rest], state) do
    case Event.parse(text) do
      {:ok, event} ->
        send(state.subscriber, {:hunter_stream, self(), event})

      {:error, reason} ->
        Logger.warning("Hunter.Streaming: skipping malformed frame: #{inspect(reason)}")
    end

    dispatch_frames(rest, state)
  end

  defp dispatch_frames([{:ping, data} | rest], state) do
    case send_frame(state, {:pong, data}) do
      {:ok, state} -> dispatch_frames(rest, state)
      {:error, state, reason} -> stop_with(state, {:error, reason}, :noreply)
    end
  end

  defp dispatch_frames([{:close, code, _reason} | _rest], state) do
    stop_with(state, {:remote, code}, :noreply)
  end

  defp dispatch_frames([_other | rest], state), do: dispatch_frames(rest, state)

  defp subscribe_initial(state, streams) do
    Enum.reduce_while(streams, {:ok, state}, fn spec, {:ok, state} ->
      {stream, params} =
        case spec do
          {stream, params} -> {stream, params}
          stream when is_binary(stream) -> {stream, []}
        end

      frame =
        params
        |> Map.new(fn {key, value} -> {to_string(key), to_string(value)} end)
        |> Map.merge(%{"type" => "subscribe", "stream" => stream})

      case send_frame(state, {:text, Poison.encode!(frame)}) do
        {:ok, state} -> {:cont, {:ok, state}}
        {:error, _state, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp send_frame(state, frame) do
    with {:ok, websocket, data} <- Mint.WebSocket.encode(state.websocket, frame),
         state = %{state | websocket: websocket},
         {:ok, conn} <- Mint.WebSocket.stream_request_body(state.conn, state.ref, data) do
      {:ok, %{state | conn: conn}}
    else
      {:error, %Mint.WebSocket{} = websocket, reason} ->
        {:error, %{state | websocket: websocket}, reason}

      {:error, conn, reason} ->
        {:error, %{state | conn: conn}, reason}
    end
  end

  defp stop_with(state, reason, reply_or_noreply) do
    send(state.subscriber, {:hunter_stream, self(), {:closed, reason}})
    Mint.HTTP.close(state.conn)

    case reply_or_noreply do
      {:reply, value} -> {:stop, :normal, value, state}
      :noreply -> {:stop, :normal, state}
    end
  end

  defp await_upgrade(conn, ref, status \\ nil, headers \\ nil) do
    receive do
      message ->
        case Mint.WebSocket.stream(conn, message) do
          {:ok, conn, entries} ->
            status = List.keyfind(entries, :status, 0, {nil, nil, status}) |> elem(2)
            headers = List.keyfind(entries, :headers, 0, {nil, nil, headers}) |> elem(2)

            if List.keymember?(entries, :done, 0) do
              {:ok, conn, status, headers}
            else
              await_upgrade(conn, ref, status, headers)
            end

          {:error, _conn, reason, _responses} ->
            {:error, reason}

          :unknown ->
            await_upgrade(conn, ref, status, headers)
        end
    after
      @handshake_timeout -> {:error, :handshake_timeout}
    end
  end

  defp schemes("wss"), do: {:https, :wss}
  defp schemes("ws"), do: {:http, :ws}
end
```

- [ ] **Step 6: Add `connect/2` to `Hunter.Streaming`**

In `lib/hunter/streaming.ex`, add `alias Hunter.Streaming.Connection` next to the existing `alias Hunter.Config`, then add above `health?/2`:

```elixir
@doc """
Opens a streaming WebSocket connection linked to the caller.

## Parameters

  * `conn` - connection credentials
  * `opts` - option list

## Options

  * `streams` - initial subscriptions: stream names or `{name, params}`
    tuples, e.g. `["user", {"hashtag", tag: "elixir"}]`
  * `subscriber` - pid that receives events, default: the caller
  * `url` - streaming base URL override, e.g. `"wss://streaming.example"`
    (see the module docs for discovery)
  * `transport_opts` - Mint transport options, e.g.
    `[verify: :verify_none]` for self-signed certificates

"""
@spec connect(Hunter.Client.t(), Keyword.t()) :: {:ok, pid} | {:error, term}
def connect(%Hunter.Client{} = conn, opts \\ []) do
  case Connection.start_link(
         uri: ws_uri(conn, opts),
         subscriber: Keyword.get(opts, :subscriber, self()),
         streams: Keyword.get(opts, :streams, []),
         transport_opts: Keyword.get(opts, :transport_opts, [])
       ) do
    {:ok, pid} -> {:ok, pid}
    {:error, reason} -> {:error, reason}
  end
end

defp ws_uri(%Hunter.Client{base_url: base_url, access_token: token}, opts) do
  base =
    case Keyword.fetch(opts, :url) do
      {:ok, url} ->
        String.trim_trailing(url, "/")

      :error ->
        base_url
        |> String.trim_trailing("/")
        |> String.replace_prefix("https://", "wss://")
        |> String.replace_prefix("http://", "ws://")
    end

  uri = URI.parse(base <> "/api/v1/streaming")
  %{uri | query: URI.encode_query(access_token: token), port: uri.port}
end
```

Note: Elixir's `URI` knows the default ports for `ws` (80) and `wss` (443), so `uri.port` is always set.

- [ ] **Step 7: Run the tests to verify they pass**

Run: `mix test test/hunter/streaming_test.exs`
Expected: PASS (7 tests, no Bandit startup noise, no stray logs outside the `:capture_log` test).

- [ ] **Step 8: Format, run the full suite, commit**

```bash
mix format
mix test
git add mix.exs mix.lock lib/hunter/streaming.ex lib/hunter/streaming/connection.ex test/support/streaming_server.ex test/support/streaming_server/handler.ex test/hunter/streaming_test.exs
git commit -m "feat: streaming WebSocket connection with event delivery"
```

---

### Task 4: `subscribe/3`, `unsubscribe/3`, `close/1`, ping/pong, close paths

**Files:**
- Modify: `lib/hunter/streaming.ex`
- Test: `test/hunter/streaming_test.exs`

**Interfaces:**
- Consumes: the GenServer calls `{:control, type, stream, params}` and `:close` implemented in Task 3's `Hunter.Streaming.Connection`, and the `Hunter.StreamingServer` scripting messages (`:ping_client`, `{:close, code}`).
- Produces: `Hunter.Streaming.subscribe(pid, String.t(), Keyword.t()) :: :ok`, `unsubscribe/3` same shape, `close(pid) :: :ok`. Task 6 uses `close/1`.

- [ ] **Step 1: Write the failing tests**

Append to `test/hunter/streaming_test.exs` (a new describe block after `connect/2`; uses the existing `client/0` helper):

```elixir
  describe "runtime control and close paths" do
    setup do
      {_server, port} = Hunter.StreamingServer.start(self())
      {:ok, pid} = Hunter.Streaming.connect(client(), url: "ws://localhost:#{port}")
      assert_receive {:ws_connected, ws}
      %{pid: pid, ws: ws}
    end

    test "subscribe/3 and unsubscribe/3 send control frames", %{pid: pid} do
      assert :ok = Hunter.Streaming.subscribe(pid, "list", list: "12")
      assert_receive {:ws_frame, %{"type" => "subscribe", "stream" => "list", "list" => "12"}}

      assert :ok = Hunter.Streaming.unsubscribe(pid, "list", list: "12")
      assert_receive {:ws_frame, %{"type" => "unsubscribe", "stream" => "list", "list" => "12"}}
    end

    test "answers server pings with pong, never surfacing them", %{pid: pid, ws: ws} do
      send(ws, :ping_client)

      assert_receive {:ws_pong, "hb"}
      refute_receive {:hunter_stream, ^pid, _}, 100
      assert Process.alive?(pid)
    end

    test "server close delivers {:closed, {:remote, code}} and exits normally", %{pid: pid, ws: ws} do
      ref = Process.monitor(pid)
      send(ws, {:close, 4_000})

      assert_receive {:hunter_stream, ^pid, {:closed, {:remote, 4_000}}}
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end

    test "server going away delivers {:closed, {:error, reason}}", %{pid: pid, ws: ws} do
      ref = Process.monitor(pid)
      Process.exit(ws, :kill)

      assert_receive {:hunter_stream, ^pid, {:closed, _reason}}
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end

    test "close/1 sends a close frame and delivers {:closed, :local}", %{pid: pid} do
      ref = Process.monitor(pid)

      assert :ok = Hunter.Streaming.close(pid)
      assert_receive {:hunter_stream, ^pid, {:closed, :local}}
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end
  end
```

Note on the kill test: depending on timing the transport error may surface as `{:error, %Mint.TransportError{reason: :closed}}` or as a remote close — the assertion only pins that a `{:closed, _}` message arrives and the exit is `:normal`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `mix test test/hunter/streaming_test.exs`
Expected: the new describe block FAILS with `UndefinedFunctionError` for `Hunter.Streaming.subscribe/3` (the first test) — the ping/close-path tests may already pass since Task 3 shipped the Connection internals; that is expected and fine (they lock the behavior in).

- [ ] **Step 3: Add the public wrappers**

In `lib/hunter/streaming.ex`, add after `connect/2`:

```elixir
@doc """
Subscribes the connection to a stream at runtime.

## Parameters

  * `pid` - the connection from `connect/2`
  * `stream` - stream name, passed through verbatim (e.g. `"user"`,
    `"public:local"`, `"hashtag"`, `"list"`)
  * `params` - stream parameters, e.g. `tag: "elixir"` or `list: "12"`

"""
@spec subscribe(pid, String.t(), Keyword.t()) :: :ok
def subscribe(pid, stream, params \\ []) do
  GenServer.call(pid, {:control, "subscribe", stream, params})
end

@doc """
Unsubscribes the connection from a stream at runtime; same arguments as
`subscribe/3`.
"""
@spec unsubscribe(pid, String.t(), Keyword.t()) :: :ok
def unsubscribe(pid, stream, params \\ []) do
  GenServer.call(pid, {:control, "unsubscribe", stream, params})
end

@doc """
Closes the connection gracefully: sends a close frame, delivers
`{:hunter_stream, pid, {:closed, :local}}` to the subscriber, and the
process exits `:normal`.
"""
@spec close(pid) :: :ok
def close(pid) do
  GenServer.call(pid, :close)
end
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `mix test test/hunter/streaming_test.exs`
Expected: PASS (12 tests).

- [ ] **Step 5: Format, run the full suite, commit**

```bash
mix format
mix test
git add lib/hunter/streaming.ex test/hunter/streaming_test.exs
git commit -m "feat: streaming subscribe/unsubscribe/close and close-path handling"
```

---

### Task 5: Delete `Hunter.EventStream`, CHANGELOG, gates

**Files:**
- Delete: `lib/hunter/event_stream.ex`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: everything from Tasks 1–4.
- Produces: release notes; a gate-clean branch for the integration task.

- [ ] **Step 1: Delete the dead module**

```bash
git rm lib/hunter/event_stream.ex
grep -rn "EventStream" lib test README.md
```

Expected: `grep` finds nothing (the module was never referenced; if a reference turns up, remove it and note it in your report).

- [ ] **Step 2: Add the CHANGELOG entries**

In `CHANGELOG.md`, the `## Unreleased` section currently contains only a `* Features` list. Make it:

```markdown
## Unreleased

  * Breaking changes
    - Removed `Hunter.EventStream` ([#3]): the SSE frame struct added in
      2017 was never wired to a connection; the streaming API ships as
      WebSocket-only (`Hunter.Streaming`)

  * Features
    - Streaming API ([#3]): `Hunter.Streaming.connect/2` opens Mastodon's
      multiplexed streaming WebSocket (new `mint_web_socket` dependency)
      with runtime `subscribe/3`/`unsubscribe/3`, graceful `close/1`, and
      `health?/2`; parsed events (`Hunter.Streaming.Event` — payloads
      decode to `Status`, `Notification`, `Conversation`, `Announcement`,
      `Announcement.Reaction`, or id strings for deletes) are delivered to
      a subscriber pid as `{:hunter_stream, pid, event}` messages. No
      automatic reconnection: the process notifies the subscriber and
      exits, so callers supervise it
    - Account extras ([#124]): `lookup_account/2`, `accounts_by_ids/2`,
```

(The Account extras bullet and everything after it stay unchanged.)

Then add the link reference next to the existing ones at the bottom of the file, after the `[#122]` line:

```markdown
[#3]: https://github.com/milmazz/hunter/issues/3
```

- [ ] **Step 3: Run the gates**

```bash
mix test
mix format --check-formatted && mix credo
mix dialyzer
```

Expected: 0 test failures; no formatting diffs; no new credo issues; no new dialyzer warnings (first run may rebuild the PLT for the new deps — that is slow but normal). Report any warning verbatim instead of hacking around it.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat!: remove Hunter.EventStream; changelog for streaming (#3)"
```

---

### Task 6: CI streaming service + integration test

**Files:**
- Modify: `docker-compose.ci.yml`
- Modify: `scripts/ci/nginx.conf`
- Modify: `scripts/ci/setup_mastodon.sh` (one line)
- Test: `test/integration/mastodon_test.exs`

**Interfaces:**
- Consumes: `Hunter.Streaming.connect/2` (`transport_opts:` option), `close/1`, `health?/2`, `Hunter.Streaming.Event` struct; `Hunter.IntegrationCase` context (`conn`), `eventually/2`; `Hunter.create_status/3` and `Hunter.destroy_status/2` on the facade.
- Produces: a CI stack whose nginx proxies `/api/v1/streaming` (WebSocket upgrade) to the Mastodon streaming server, and one integration test proving the full path.

- [ ] **Step 1: Add the streaming service to the compose file**

In `docker-compose.ci.yml`, add after the `sidekiq` service (Mastodon ships streaming as its own image since 4.2 — same tag as `web`):

```yaml
  streaming:
    image: ghcr.io/mastodon/mastodon-streaming:v4.3.8
    env_file: scripts/ci/.env.mastodon
    command: node ./streaming
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "wget -q --spider --proxy=off localhost:4000/api/v1/streaming/health || exit 1"
        ]
      interval: 5s
      timeout: 5s
      retries: 30
```

And make `nginx` wait for it — in the `nginx` service's `depends_on`, add:

```yaml
      streaming:
        condition: service_healthy
```

- [ ] **Step 2: Proxy the streaming path through nginx**

In `scripts/ci/nginx.conf`, add a second `location` block inside the existing `server` block, before `location /`:

```nginx
    location /api/v1/streaming {
      proxy_pass http://streaming:4000;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host localhost;
      proxy_set_header X-Forwarded-Proto https;
      proxy_read_timeout 120s;
    }
```

- [ ] **Step 3: Boot the new service in the setup script**

In `scripts/ci/setup_mastodon.sh`, the stack boot line currently reads:

```bash
$COMPOSE up -d web sidekiq nginx
```

Change it to:

```bash
$COMPOSE up -d web sidekiq streaming nginx
```

- [ ] **Step 4: Write the integration test**

Append to `test/integration/mastodon_test.exs`, before the file's final `end`:

```elixir
  describe "streaming" do
    test "health check and live user-stream update", %{conn: conn} do
      assert Hunter.Streaming.health?(conn)

      {:ok, pid} =
        Hunter.Streaming.connect(conn,
          streams: ["user"],
          transport_opts: [verify: :verify_none]
        )

      status = Hunter.create_status(conn, "streaming test #{System.unique_integer([:positive])}")

      try do
        status_id = status.id

        assert_receive {:hunter_stream, ^pid,
                        %Hunter.Streaming.Event{
                          type: "update",
                          payload: %Hunter.Status{id: ^status_id}
                        }},
                       30_000

        Hunter.Streaming.close(pid)
        assert_receive {:hunter_stream, ^pid, {:closed, :local}}
      after
        Hunter.destroy_status(conn, status.id)
      end
    end
  end
```

- [ ] **Step 5: Run the integration test against a local stack**

```bash
./scripts/ci/setup_mastodon.sh
source scripts/ci/.env.hunter
mix test --only integration
```

Expected: the whole integration suite PASSES including the new streaming test. If the stack is already running from a previous session, tear it down first (`docker compose -f docker-compose.ci.yml down -v`) so the new streaming service and nginx config load. If Docker is unavailable in your environment, report that verbatim as a concern instead of skipping silently — the controller will run it in CI.

- [ ] **Step 6: Run the unit gates and commit**

```bash
mix test
mix format --check-formatted && mix credo
git add docker-compose.ci.yml scripts/ci/nginx.conf scripts/ci/setup_mastodon.sh test/integration/mastodon_test.exs
git commit -m "feat: streaming integration test and CI streaming service"
```

---

## Self-Review Notes

Spec coverage: `connect/subscribe/unsubscribe/close` (Tasks 3–4), `health?` (Task 2), `Event` parsing table incl. `:announcement_reaction` clause and unknown-type passthrough (Task 1), subscriber message contract incl. the single `{:closed, reason}` path with `:local`/`{:remote, code}`/`{:error, term}` (Tasks 3–4), handshake-failure `{:error, reason}` with no leftover process (Task 3, GenServer `init` `{:stop, reason}`), malformed-frame skip with `Logger.warning` (Tasks 1+3), `EventStream` deletion + CHANGELOG breaking entry (Task 5), scripted-WS-server unit tests + `Req.Test` health tests + real-Mastodon integration incl. the CI streaming container (Tasks 3, 2, 6). Out-of-scope items (SSE, reconnect, URL auto-discovery) have no tasks, as intended. Type consistency: `{:control, type, stream, params}`/`:close` GenServer messages match between Task 3 (implementation) and Task 4 (wrappers); `Hunter.StreamingServer.start/1` → `{server, port}` used identically in Tasks 3 and 4; `transport_opts:` flows `connect/2` → `Connection.start_link/1` → `Mint.HTTP.connect/4` and is exercised in Task 6. One deliberate addition over the spec: the `transport_opts:` connect option — required for the CI stack's self-signed certificate; it is the Mint-level twin of the `req_options` override the integration case already applies to REST calls.
