# Changelog

## Unreleased

  * Breaking changes
    - Require Elixir 1.15+ and Erlang/OTP 26+ (transitive dependencies of
      httpoison 3.0 no longer compile on OTP 25)
    - `Hunter.Result.hashtags` is now a list of `Hunter.Tag` structs (the
      `/api/v2/search` shape) instead of strings.
    - Removed `Hunter.follow_by_uri/2` / `Hunter.Account.follow_by_uri/2`:
      Mastodon 4.0 removed `POST /api/v1/follows`. Search for the account and
      use `Hunter.follow/2` instead.
    - Removed `Hunter.reports/1` / `Hunter.Report.reports/1`: Mastodon removed
      `GET /api/v1/reports`. Filing reports via `Hunter.report/4` still works.
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
