# Changelog

## v0.4.1

  * Fixes
    - Set default value for `hunter_api`: `Hunter.Api.HTTPClient`

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
