# Changelog

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
