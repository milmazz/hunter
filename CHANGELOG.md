# Changelog

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
      `familiar_followers/2` (new `Hunter.FamiliarFollowers` entity),
      `account_featured_tags/2`, `register_account/2` (returns a
      `Hunter.Client` holding the new user's token), `set_account_note/3`,
      `remove_from_followers/2`, and endorsements (`endorse/2`,
      `unendorse/2`, `endorsements/2`, `account_endorsements/3`), all on
      `Hunter`

## v0.7.0

  * Breaking changes
    - Flatten the facade: every endpoint function that used to live on an
      entity module (`Hunter.Account`, `Hunter.Application`,
      `Hunter.Attachment`, `Hunter.Client`, `Hunter.Context`,
      `Hunter.Instance`, `Hunter.List`, `Hunter.Notification`, `Hunter.Poll`,
      `Hunter.Relationship`, `Hunter.Report`, `Hunter.Result`,
      `Hunter.Status`, `Hunter.WebPushSubscription`) was removed and now
      lives only on `Hunter`, with the exact same name, arity, and default
      arguments — the return value is unchanged. These modules are now pure
      data definitions (`defstruct`, `@type t`, and field docs only); their
      `@type t` structs are otherwise unchanged. `Hunter.Domain` had no
      struct and was deleted entirely; its three functions moved to
      `Hunter` unchanged. Migration is mechanical: replace
      `Hunter.<Entity>.<function>(...)` with `Hunter.<function>(...)` at
      every call site, per the table below. Internally,
      `Hunter.Api.HTTPClient` was deleted; the single transport is now
      `Hunter.Api.Request.request!/6`

      | Old module | Old call → new call |
      |---|---|
      | `Hunter.Account` | `Hunter.Account.followers/3` → `Hunter.followers/3`; also `account/2`, `verify_credentials/1`, `update_credentials/2`, `following/3`, `search_account/2`, `blocks/2`, `follow_requests/2`, `mutes/2`, `accept_follow_request/2`, `reject_follow_request/2`, `reblogged_by/3`, `favourited_by/3` |
      | `Hunter.Application` | `Hunter.Application.create_app/5` → `Hunter.create_app/5`; `Hunter.Application.load_credentials/1` → `Hunter.load_credentials/1` |
      | `Hunter.Attachment` | `Hunter.Attachment.upload_media/3` → `Hunter.upload_media/3`; also `media_attachment/2`, `update_media/3`, `delete_media/2` |
      | `Hunter.Client` | `Hunter.Client.new/1` → `Hunter.new/1`; `Hunter.Client.log_in/4` → `Hunter.log_in/4`; `Hunter.Client.log_in_oauth/3` → `Hunter.log_in_oauth/3`; `Hunter.Client.user_agent/0` → `Hunter.user_agent/0` |
      | `Hunter.Context` | `Hunter.Context.status_context/2` → `Hunter.status_context/2` |
      | `Hunter.Domain` (module deleted) | `Hunter.Domain.blocked_domains/2` → `Hunter.blocked_domains/2`; also `block_domain/2`, `unblock_domain/2` |
      | `Hunter.Instance` | `Hunter.Instance.instance_info/1` → `Hunter.instance_info/1` |
      | `Hunter.List` | `Hunter.List.lists/1` → `Hunter.lists/1`; also `list/2`, `create_list/3`, `update_list/3`, `destroy_list/2`, `list_accounts/3`, `add_accounts_to_list/3`, `remove_accounts_from_list/3`, `account_lists/2` |
      | `Hunter.Notification` | `Hunter.Notification.notifications/2` → `Hunter.notifications/2`; also `notification/2`, `clear_notifications/1`, `clear_notification/2`, `unread_count/1`, `notification_policy/1`, `update_notification_policy/2`, `notification_requests/2`, `notification_request/2`, `accept_notification_request/2`, `dismiss_notification_request/2`, `accept_notification_requests/2`, `dismiss_notification_requests/2`, `notification_requests_merged?/1`, `grouped_notifications/2`, `notification_group/2`, `dismiss_notification_group/2`, `notification_group_accounts/2`, `grouped_unread_count/1` |
      | `Hunter.Poll` | `Hunter.Poll.poll/2` → `Hunter.poll/2`; `Hunter.Poll.vote/3` → `Hunter.vote/3` |
      | `Hunter.Relationship` | `Hunter.Relationship.follow/2` → `Hunter.follow/2`; also `unfollow/2`, `block/2`, `unblock/2`, `mute/2`, `unmute/2`, `relationships/2` |
      | `Hunter.Report` | `Hunter.Report.report/4` → `Hunter.report/4` |
      | `Hunter.Result` | `Hunter.Result.search/3` → `Hunter.search/3` |
      | `Hunter.Status` | `Hunter.Status.create_status/3` → `Hunter.create_status/3`; also `status/2`, `statuses_by_ids/2`, `edit_status/4`, `status_history/2`, `status_source/2`, `bookmark/2`, `unbookmark/2`, `bookmarks/2`, `pin/2`, `unpin/2`, `mute_conversation/2`, `unmute_conversation/2`, `translate_status/3`, `destroy_status/2`, `reblog/2`, `unreblog/2`, `favourite/2`, `unfavourite/2`, `favourites/2`, `statuses/3`, `home_timeline/2`, `public_timeline/2`, `hashtag_timeline/3`, `list_timeline/3` |
      | `Hunter.WebPushSubscription` | `Hunter.WebPushSubscription.create_push_subscription/3` → `Hunter.create_push_subscription/3`; also `push_subscription/1`, `update_push_subscription/2`, `delete_push_subscription/1` |

    - Typespec honesty ([#116]): entity `id` fields are now typed
      `String.t()` — what Mastodon has returned since 2.0 and what the
      structs actually held at runtime; id parameters accept
      `String.t() | non_neg_integer` as before
    - Fire-and-forget endpoints (`destroy_status`, `destroy_list`,
      `delete_media`, `clear_notification(s)`, `block_domain`,
      `unblock_domain`, `add_accounts_to_list`,
      `remove_accounts_from_list`) now return `true` as their `boolean`
      specs always promised, instead of leaking the decoded response
      body ([#116])
    - Require Elixir 1.16+ (media uploads stream the file in raw byte
      chunks, which needs the `File.stream!(path, bytes)` argument order
      introduced in 1.16); the 1.15 floor existed only for httpoison's
      transitive dependencies, which are gone
    - The HTTP stack migrated from HTTPoison/hackney to
      [Req](https://hex.pm/packages/req) ([#103]). The `:http_options`
      configuration key was replaced by `:req_options`, which takes
      [Req options](https://hexdocs.pm/req/Req.html#new/1)
    - The `Hunter.Api` behaviour and the `:hunter_api` adapter configuration
      were removed ([#103]). Entity modules now call the HTTP client
      directly; to stub Hunter in your tests, intercept requests at the HTTP
      layer with [`Req.Test`](https://hexdocs.pm/req/Req.Test.html) via
      `config :hunter, req_options: [plug: {Req.Test, MyStub}]`

  * Features
    - Notifications v2 ([#122]): `unread_count/1`, the notification
      filtering policy (`notification_policy/1`,
      `update_notification_policy/2`), notification requests
      (`notification_requests/2`, `notification_request/2`,
      `accept_notification_request/2`, `dismiss_notification_request/2`,
      bulk accept/dismiss, `notification_requests_merged?/1`) and grouped
      notifications (`grouped_notifications/2`, `notification_group/2`,
      `dismiss_notification_group/2`, `notification_group_accounts/2`,
      `grouped_unread_count/1`, new `Hunter.GroupedNotificationsResults`
      entity), all on `Hunter`
    - Web Push subscriptions ([#122]): `create_push_subscription/3`,
      `push_subscription/1`, `update_push_subscription/2` and
      `delete_push_subscription/1` on `Hunter`
    - Lists support ([#121]): `lists/1`, `list/2`, `create_list/3`,
      `update_list/3`, `destroy_list/2`, `list_accounts/3`,
      `add_accounts_to_list/3`, `remove_accounts_from_list/3`,
      `account_lists/2` and the `list_timeline/3` timeline, all exposed on
      the `Hunter` facade
    - Status parity endpoints ([#120]): `edit_status/4`, `status_history/2`,
      `status_source/2`, `bookmark/2`, `unbookmark/2`, `bookmarks/2`,
      `pin/2`, `unpin/2`, `mute_conversation/2`, `unmute_conversation/2`,
      `translate_status/3` and `statuses_by_ids/2` (all also exposed on the
      `Hunter` facade)
    - Polls ([#120]): `Hunter.poll/2` and `Hunter.vote/3`, plus
      the `poll` option on `create_status`
    - `create_status` upgrades ([#120]): `language` and `quoted_status_id`
      options; `scheduled_at` returns a `Hunter.ScheduledStatus`;
      `idempotency_key` is sent as the `Idempotency-Key` header
    - Media management ([#120]): `media_attachment/2` (processing status of
      async uploads), `update_media/3` and `delete_media/2`
    - New entities `Hunter.StatusSource` and `Hunter.StatusEdit` backing the
      status source/history endpoints ([#120])
    - Modernized the existing entity structs to the Mastodon 4.6 shapes
      ([#119]):
      - `Hunter.Status`: `text`, `edited_at`, `replies_count`, `bookmarked`,
        `pinned`, `emojis`, `poll`, `filtered`, `quote`, `quote_approval`
      - `Hunter.Account`: `uri`, `last_status_at`, `group`, `discoverable`,
        `noindex`, `suspended`, `limited`, `hide_collections`, `roles`,
        `attribution_domains`, `source`; `fields` is now a list of
        `Hunter.Field` structs
      - `Hunter.Relationship`: `showing_reblogs`, `notifying`, `languages`,
        `blocked_by`, `muting_notifications`, `muting_expires_at`,
        `requested_by`, `endorsed`, `note`
      - `Hunter.Notification`: `group_key`, `report`, `event`,
        `moderation_warning`
      - `Hunter.Tag`: `id`, `history`, `following`, `featuring`
      - `Hunter.Card`: `blurhash`, `embed_url`, `authors` (list of
        `Hunter.Card.Author`), plus `published_at`/`history` for trending
        links
      - `Hunter.Attachment`: `blurhash`, `preview_remote_url`
      - `Hunter.Emoji`: `category`
      - `Hunter.Application`: `name`, `website`, `redirect_uris`,
        `client_secret_expires_at` (the `CredentialApplication` shape)
      - `Hunter.Instance.rules` is now a list of `Hunter.Rule` structs
    - New entity structs, ready for the endpoints that return them ([#119]):
      `Hunter.Poll` (and `Hunter.Poll.Option`), `Hunter.Quote`,
      `Hunter.Filter`, `Hunter.FilterKeyword`, `Hunter.FilterStatus`,
      `Hunter.FilterResult`, `Hunter.Translation`, `Hunter.ScheduledStatus`,
      `Hunter.List`, `Hunter.Conversation`, `Hunter.Marker`,
      `Hunter.Suggestion`, `Hunter.FeaturedTag`, `Hunter.Announcement` (and
      `Hunter.Announcement.Reaction`), `Hunter.Preferences`, `Hunter.Field`,
      `Hunter.Role`, `Hunter.NotificationPolicy`,
      `Hunter.NotificationRequest`, `Hunter.NotificationGroup`,
      `Hunter.WebPushSubscription`, `Hunter.Rule`,
      `Hunter.ExtendedDescription`, `Hunter.PrivacyPolicy`,
      `Hunter.TermsOfService`, `Hunter.DomainBlock`, `Hunter.Collection`
      (and `Hunter.Collection.Item`), `Hunter.AnnualReport`

[#119]: https://github.com/milmazz/hunter/issues/119
[#120]: https://github.com/milmazz/hunter/issues/120
[#121]: https://github.com/milmazz/hunter/issues/121
[#103]: https://github.com/milmazz/hunter/issues/103
[#116]: https://github.com/milmazz/hunter/issues/116
[#122]: https://github.com/milmazz/hunter/issues/122
[#3]: https://github.com/milmazz/hunter/issues/3
[#124]: https://github.com/milmazz/hunter/issues/124

## v0.6.0

  * Features
    - `Hunter.log_in_oauth/3`: obtain an access token from an OAuth
      authorization code (the authorization-code grant), complementing the
      existing password-grant `Hunter.log_in/4`
    - `Hunter.Application` now records the `scopes` and `redirect_uri` the
      app was registered with (persisted by `save?: true`), so the login
      helpers can request them

  * Breaking changes
    - Require Elixir 1.15+ and Erlang/OTP 26+ (transitive dependencies of
      httpoison 3.0 no longer compile on OTP 25)
    - Major dependency upgrades: httpoison 1.x → 3.0 and poison 4.x/5.x →
      6.0; check for version conflicts with sibling dependencies in your tree
    - `Hunter.Result.hashtags` is now a list of `Hunter.Tag` structs (the
      `/api/v2/search` shape) instead of strings.
    - Removed the `follow_by_uri` function (`Hunter` and `Hunter.Account`):
      Mastodon 4.0 removed `POST /api/v1/follows`. Search for the account and
      use `Hunter.follow/2` instead.
    - Removed the `reports` listing function (`Hunter` and `Hunter.Report`):
      Mastodon removed `GET /api/v1/reports`. Filing reports via
      `Hunter.report/4` still works.
    - The `Hunter.Api` behaviour contract changed: `log_in_oauth/3` is a new
      required callback; the `follow_by_uri`/`reports`/`card_by_status`
      callbacks were removed; and `follow_request_action` now returns a
      `Hunter.Relationship` — custom API adapters need updating
    - `Hunter.Client` field `bearer_token` was renamed to `access_token` for
      consistency with other Mastodon client libraries; update
      `Hunter.Client.new(bearer_token: …)` calls to `access_token:` ([#101])
    - Removed the `card_by_status` function (`Hunter` and `Hunter.Card`):
      Mastodon 3.0 removed the endpoint. The preview card is now embedded in
      `Hunter.Status` as the `card` field ([#118])
    - `accept_follow_request/2` and `reject_follow_request/2` now call the
      documented per-id endpoints and return a `Hunter.Relationship` instead
      of a boolean; the previous implementation matched no Mastodon version
      and could only fail ([#118])
    - `Hunter.Instance` reshaped to the `GET /api/v2/instance` entity
      (`domain`, `configuration`, `contact`, …); nested objects decode as
      plain maps for now ([#118])

  * Bug fixes
    - GET/DELETE request options now travel as query-string parameters instead
      of JSON request bodies, which proxies routinely drop ([#74])
    - `Hunter.log_in/4` now requests the scopes the app was registered with;
      previously the token silently fell back to Mastodon's default `read`
      scope, making every write action fail with "This action is outside the
      authorized scopes" ([#100]). Re-run `create_app` once to refresh saved
      credentials created by older hunter versions.
    - `block_domain/2` and `unblock_domain/2` now send the `Authorization`
      header; previously they always failed with "The access token is
      invalid" ([#110])
    - `Hunter.log_in_oauth/3` now sends the `redirect_uri` in the token
      exchange; Doorkeeper rejects the authorization-code grant without it,
      so the function could never succeed. `Hunter.Application` records the
      redirect URI the app was registered with; stale saved credentials fall
      back to `urn:ietf:wg:oauth:2.0:oob` ([#112])
    - Account `emojis` now decode as `Hunter.Emoji` structs, matching the
      documented typespec; previously they were plain maps ([#107])
    - Notification dismissal uses the documented
      `POST /api/v1/notifications/:id/dismiss` path; the previous path
      matched no Mastodon version ([#118])
    - Media uploads use `POST /api/v2/media` (v1 deprecated since Mastodon
      3.1.3); large files process asynchronously and the attachment `url`
      may be `nil` until ready ([#118])

## v0.5.1

  * Bug fixes
    - Fix publishing new statuses (#14)

## v0.5.0

  * Features
    - Add Emoji entity, add new fields on Account entity
    - Fix upload_media
    - Updated some dependencies
    - Include new attributes in some Entities
    - Improve exception handling
    - Move `reblogged_by` and `favourited_by` to Account module
    - Update endpoints according to recent docs
    - Fix `create_status` and `relationships` endpoints
    - Refactor HTTP Client
    - Set default values for API base url and home
    - Fix some specs
  * Documentation
    - Hide internal details from docs
    - Fix link to server-sent events docs
    - Add more examples in the docs

## v0.4.0

  * Features
    - Update current user: `Hunter.update_credentials/2`
    - Register an application: `Hunter.create_app/5`
    - Load persisted app credentials: `Hunter.load_credentials/1`
    - Acquire access token: `Hunter.log_in/4`
    - Get who reblogged a status: `Hunter.reblogged_by/2`
    - Get who favorited a status: `Hunter.favourited_by/2`
    - Authorize follow requests: `Hunter.accept_follow_request/2`
    - Reject follow requests: `Hunter.reject_follow_request/2`
  * Documentation
    - Add more examples in the README
    - How to contribute guide
    - Code of conduct

## v0.3.0

  * Features:
    - Search for accounts or content
    - Get an account's relationship
    - Fetch user's blocks
    - Fetch a list of follow requests
    - Fetch user's mutes
    - Get instance information
    - Fetch user's notifications
    - Getting a single notification
    - Clear notifications
    - Fetch user's reports
    - Report a user
    - Get status context
    - Get a card associated with a status

## v0.2.0

  * Features:
    - Add media files
    - Fetching user's favorites
    - (un)favoriting a status

 ## v0.1.0

  * Initial release

[#74]: https://github.com/milmazz/hunter/issues/74
[#100]: https://github.com/milmazz/hunter/issues/100
[#101]: https://github.com/milmazz/hunter/issues/101
[#110]: https://github.com/milmazz/hunter/issues/110
[#112]: https://github.com/milmazz/hunter/issues/112
[#107]: https://github.com/milmazz/hunter/issues/107
[#118]: https://github.com/milmazz/hunter/issues/118
