defmodule Hunter.Account do
  @moduledoc """
  Account entity

  This module defines a `Hunter.Account` struct.

  ## Fields

    * `id` - the id of the account
    * `username` - the username of the account
    * `acct` - equals `username` for local users, includes `@domain` for remote ones
    * `display_name` - the account's display name
    * `locked` - boolean for when the account cannot be followed without waiting for approval first
    * `created_at` - the time the account was created
    * `followers_count` - the number of followers for the account
    * `following_count` - the number of accounts the given account is following
    * `statuses_count` - the number of statuses the account has made
    * `note` - biography of user
    * `url` - URL of the user's profile page (can be remote)
    * `avatar` - URL to the avatar image
    * `avatar_static` - URL to the avatar static image (gif)
    * `header` - URL to the header image
    * `header_static` - URL to the header static image (gif)
    * `emojis` - list of emojis
    * `moved` - moved from account
    * `fields` - list of `Hunter.Field`, additional profile metadata
    * `bot` - whether this account is a bot or not
    * `group` - whether this account represents a group actor
    * `discoverable` - whether the account has opted into discovery features
    * `noindex` - whether the local user has opted out of search engine indexing
    * `suspended` - whether the account has been suspended (returns with
      limited profile data when true)
    * `limited` - whether the account has been silenced
    * `last_status_at` - date (not time) of the account's last status, if any
    * `hide_collections` - whether the user hides their followers/following collections
    * `uri` - the ActivityPub actor URI of the account
    * `roles` - list of `Hunter.Role` with a visible badge
    * `attribution_domains` - domains allowed to credit the account in link previews
    * `source` - profile source data as entered by the user (plain-text `note`,
      default `privacy`, etc.), only returned by `verify_credentials` and
      `update_credentials`

  """

  @type t :: %__MODULE__{
          id: String.t(),
          username: String.t(),
          acct: String.t(),
          display_name: String.t(),
          note: String.t(),
          url: String.t(),
          uri: String.t(),
          avatar: String.t(),
          avatar_static: String.t(),
          header: String.t(),
          header_static: String.t(),
          locked: String.t(),
          created_at: String.t(),
          last_status_at: String.t() | nil,
          followers_count: non_neg_integer,
          following_count: non_neg_integer,
          statuses_count: non_neg_integer,
          emojis: [Hunter.Emoji.t()],
          moved: t(),
          fields: [Hunter.Field.t()],
          bot: boolean,
          group: boolean,
          discoverable: boolean | nil,
          noindex: boolean | nil,
          suspended: boolean | nil,
          limited: boolean | nil,
          hide_collections: boolean | nil,
          roles: [Hunter.Role.t()],
          attribution_domains: [String.t()],
          source: map | nil
        }

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :username,
    :acct,
    :display_name,
    :note,
    :url,
    :uri,
    :avatar,
    :avatar_static,
    :header,
    :header_static,
    :locked,
    :created_at,
    :last_status_at,
    :followers_count,
    :following_count,
    :statuses_count,
    :emojis,
    :moved,
    :fields,
    :bot,
    :group,
    :discoverable,
    :noindex,
    :suspended,
    :limited,
    :hide_collections,
    :roles,
    :attribution_domains,
    :source
  ]
end
