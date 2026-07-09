defmodule Hunter.Application do
  @moduledoc """
  Application entity

  This module defines a `Hunter.Application` struct.

  The struct covers both the `Application` entity embedded in statuses
  (`name` and `website` only) and the `CredentialApplication` entity returned
  when registering an app (which adds the client credentials).

  ## Fields

    * `id` -  identifier
    * `name` - the name of the application
    * `website` - the website associated with the application, if any
    * `client_id` - client id
    * `client_secret` - client secret
    * `client_secret_expires_at` - when the client secret expires, currently
      always `0` (never expires)
    * `scopes` - scopes requested when the app was registered
    * `redirect_uris` - redirect URIs the app was registered with
    * `redirect_uri` - redirect URI the app was registered with (deprecated
      since Mastodon 4.3 in favor of `redirect_uris`)

  """

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t() | nil,
          website: String.t() | nil,
          client_id: String.t(),
          client_secret: String.t(),
          client_secret_expires_at: non_neg_integer | nil,
          scopes: [String.t()] | nil,
          redirect_uris: [String.t()] | nil,
          redirect_uri: String.t() | nil
        }

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :name,
    :website,
    :client_id,
    :client_secret,
    :client_secret_expires_at,
    :scopes,
    :redirect_uris,
    :redirect_uri
  ]
end
