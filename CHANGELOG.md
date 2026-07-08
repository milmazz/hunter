# Changelog

## Unreleased

  * Features
    - Lists support ([#121]): `lists/1`, `list/2`, `create_list/3`,
      `update_list/3`, `destroy_list/2`, `list_accounts/3`,
      `add_accounts_to_list/3`, `remove_accounts_from_list/3`,
      `account_lists/2` (`Hunter.List`) and the `list_timeline/3` timeline
      (`Hunter.Status`), all exposed on the `Hunter` facade
    - Status parity endpoints ([#120]): `edit_status/4`, `status_history/2`,
      `status_source/2`, `bookmark/2`, `unbookmark/2`, `bookmarks/2`,
      `pin/2`, `unpin/2`, `mute_conversation/2`, `unmute_conversation/2`,
      `translate_status/3` and `statuses_by_ids/2` (all also exposed on the
      `Hunter` facade)
    - Polls ([#120]): `Hunter.Poll.poll/2` and `Hunter.Poll.vote/3`, plus
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
