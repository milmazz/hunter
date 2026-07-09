defmodule Hunter.Instance do
  @moduledoc """
  Instance entity

  This module defines a `Hunter.Instance` struct.

  ## Fields

    * `domain` - The instance's domain name
    * `title` - The instance's title
    * `version` - The Mastodon version used by instance
    * `source_url` - The URL for the source code of the software running this instance
    * `description` - A short, plain-text description of the instance
    * `usage` - Statistics about how much use the instance has seen
    * `thumbnail` - Assets associated with server branding
    * `languages` - Primary languages of the instance and its staff
    * `configuration` - Configured values and limits for this instance
    * `registrations` - Information about registering for this instance
    * `contact` - Hints related to contacting a representative of the instance
    * `rules` - An itemized list of `Hunter.Rule` for this instance

  """

  @type t :: %__MODULE__{
          domain: String.t(),
          title: String.t(),
          version: String.t(),
          source_url: String.t(),
          description: String.t(),
          usage: map,
          thumbnail: map,
          languages: [String.t()],
          configuration: map,
          registrations: map,
          contact: map,
          rules: [Hunter.Rule.t()]
        }

  @derive [Poison.Encoder]
  defstruct [
    :domain,
    :title,
    :version,
    :source_url,
    :description,
    :usage,
    :thumbnail,
    :languages,
    :configuration,
    :registrations,
    :contact,
    :rules
  ]
end
