# Streaming API: multiplexed WebSocket connection

Issue: #3. Part of the Mastodon 4.6 API parity effort. Builds on the Req
migration (#103, done) — mint is already in the dependency tree via
Req/Finch.

## Goal

Receive timeline/notification updates in real time over Mastodon's
multiplexed WebSocket endpoint (`WSS /api/v1/streaming`, Mastodon 3.3+),
with runtime subscribe/unsubscribe, parsed entity payloads, and a health
check. WebSocket only: the legacy per-stream SSE endpoints are out of
scope (follow-up issue if ever wanted).

## Decisions (settled during brainstorming)

- **Transport:** WebSocket only, via a new `mint_web_socket ~> 1.0`
  dependency.
- **Consumer API:** a supervised-by-the-caller connection process that
  sends parsed events to a subscriber pid as tagged tuples.
- **Reconnection:** none in v1. The process notifies the subscriber and
  exits `:normal`; consumers restart it under their own supervision.
  Auto-reconnect can be added later without breaking the API.
- **Structure:** one GenServer plus a pure event-parsing module. Hunter
  stays a pure library — no OTP application or supervision tree.
- **Testing:** scripted local WebSocket server (test-only `bandit` +
  `websock_adapter` deps) for unit tests, plus a happy-path test against
  the real Mastodon streaming service in CI.

## Files

- `lib/hunter/streaming.ex` — `Hunter.Streaming`, the consumer-facing API
- `lib/hunter/streaming/connection.ex` — `Hunter.Streaming.Connection`,
  the GenServer owning the Mint conn and WebSocket state
- `lib/hunter/streaming/event.ex` — `Hunter.Streaming.Event`, the event
  struct and pure frame parser
- Delete `lib/hunter/event_stream.ex` (`Hunter.EventStream`): SSE-specific,
  added 2017, never wired to anything. Breaking change, documented in the
  CHANGELOG under `## Unreleased`.

## Public API (`Hunter.Streaming`)

```elixir
@spec connect(Hunter.Client.t(), Keyword.t()) :: {:ok, pid} | {:error, term}
def connect(conn, opts \\ [])
```

Opens `wss://<host of conn.base_url>/api/v1/streaming?access_token=<token>`
and links the connection process to the caller. Options:

- `streams:` — initial subscriptions, list of `stream` or `{stream, params}`
  (e.g. `["user", {"hashtag", tag: "elixir"}]`), subscribed immediately
  after the handshake
- `subscriber:` — pid receiving events, default `self()`
- `url:` — full streaming base URL override (e.g.
  `"wss://streaming.example.com"`) for instances whose streaming host
  differs from the REST host. Callers can discover it via
  `Hunter.instance_info/1` → `configuration["urls"]["streaming"]`; Hunter
  does **not** auto-fetch it.

```elixir
@spec subscribe(pid, String.t(), Keyword.t()) :: :ok
@spec unsubscribe(pid, String.t(), Keyword.t()) :: :ok
```

Send the JSON control frame
`{"type": "subscribe" | "unsubscribe", "stream": ..., ...params}`.
Examples: `subscribe(pid, "user")`, `subscribe(pid, "hashtag", tag: "elixir")`,
`subscribe(pid, "list", list: "12")`. Stream names are passed through
verbatim (`"user"`, `"user:notification"`, `"public"`, `"public:media"`,
`"public:local"`, `"public:local:media"`, `"public:remote"`,
`"public:remote:media"`, `"hashtag"`, `"hashtag:local"`, `"list"`,
`"direct"`) — no client-side validation, so new server-side streams work
without a Hunter release.

```elixir
@spec close(pid) :: :ok
```

Graceful shutdown: sends a close frame, delivers
`{:closed, :local}` to the subscriber (same single code path as every
other close), then the process exits `:normal`.

```elixir
@spec health?(Hunter.Client.t(), Keyword.t()) :: boolean
```

`GET /api/v1/streaming/health` (Mastodon 2.5) on the streaming host
(same `url:` override). The endpoint returns plain-text `"OK"`, not JSON,
so this bypasses `Hunter.Api.Transformer` and issues the request directly
through `Req` with `Hunter.Config.req_options/0` (so tests can stub it).
Returns `true` on a 200 `"OK"` body; `false` on anything else, including
transport errors.

## Messages to the subscriber

- `{:hunter_stream, connection_pid, %Hunter.Streaming.Event{}}` — one per
  parsed event frame
- `{:hunter_stream, connection_pid, {:closed, reason}}` — sent once when
  the socket closes for any reason (`reason`: `{:remote, code}` for a
  server close frame, `{:error, term}` for a transport drop, `:local`
  after `close/1`), after which the process exits `:normal`

Server ping frames are answered with pong by the connection process and
never surfaced.

## Event parsing (`Hunter.Streaming.Event`)

Mastodon WebSocket frames are JSON:
`{"stream": ["user"], "event": "update", "payload": "<JSON-encoded string>"}`
— note the payload is a JSON *string* (double-encoded), except for
payload-less events. `parse/1` is pure: frame binary in, struct out.

```elixir
@type t :: %__MODULE__{
        streams: [String.t()],
        type: String.t(),
        payload: term
      }
```

Payload mapping (inner payload decoded via existing
`Hunter.Api.Transformer` targets):

| `event` | payload decodes to |
|---|---|
| `update`, `status.update` | `Hunter.Status.t` (`:status`) |
| `notification` | `Hunter.Notification.t` (`:notification`) |
| `conversation` | `Hunter.Conversation.t` (`:conversation`) |
| `announcement` | `Hunter.Announcement.t` (`:announcement`) |
| `announcement.reaction` | `Hunter.Announcement.Reaction.t` |
| `delete`, `announcement.delete` | the id, as `String.t` |
| `filters_changed`, `notifications_merged` | `nil` |
| anything else | raw payload passed through undecoded |

Unknown event types are **delivered**, not dropped — forward
compatibility with new Mastodon releases.

`announcement.reaction` needs a small new transformer clause
(`:announcement_reaction` → `%Hunter.Announcement.Reaction{}`); all other
targets already exist.

## Error handling

- Handshake failure (non-101 response, TLS/TCP error): `connect/2`
  returns `{:error, reason}`; no process is left running.
- Malformed/unparseable frame: `Logger.warning` and skip; the connection
  stays up.
- Server close frame or transport drop: `{:closed, reason}` message, then
  `:normal` exit (linked callers are not killed).

## Testing

- **`Hunter.Streaming.Event` unit tests** (pure): one test per event type
  from the table above, reusing existing entity fixtures
  (`status.json`, `notification.json`, `conversation.json`,
  `announcement.json`) wrapped in WS frame JSON; plus unknown-type
  passthrough and malformed-frame cases.
- **Connection tests** against a real in-process WebSocket server:
  test-only deps `bandit` + `websock_adapter`, a scripted WebSock handler
  driven per-test. Covers: handshake carries the `access_token` query
  param; `streams:` option and `subscribe/3` emit correct control frames;
  event frames arrive as `{:hunter_stream, pid, %Event{}}`; server ping →
  client pong; server close → `{:closed, {:remote, code}}` + normal exit;
  `close/1` sends a close frame. Real handshake through mint_web_socket —
  no transport mocking.
- **`health?/2` unit test** via the existing `Req.Test` stub harness
  (plain-text `"OK"` response → `true`; 404 → `false`).
- **Integration** (real Mastodon in CI): add the `streaming` service
  (Mastodon's separate Node process; same image, `bundle`-less
  `node ./streaming` entrypoint, port 4000) to `docker-compose.ci.yml`
  with a healthcheck on `/api/v1/streaming/health`. One happy-path test:
  `health?/1` is true; connect to the `user` stream, post a status over
  REST, assert the `update` event arrives as `%Hunter.Status{}`.

## Out of scope

- SSE transport (the per-stream `GET /api/v1/streaming/*` HTTP endpoints)
- Auto-reconnect/backoff
- Streaming-URL auto-discovery inside `connect/2`
- Admin/direct-message-conversation streams beyond the pass-through
  stream names listed above
