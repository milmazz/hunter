defmodule Hunter.Collection do
  @moduledoc """
  Collection entity

  A curated collection of accounts

  ## Fields

    * `id` - the ID of the collection
    * `account_id` - the ID of the account that created the collection
    * `uri` - the ActivityPub URI of the collection
    * `url` - a web URL for the collection, if any
    * `name` - the name of the collection
    * `description` - HTML description of the collection
    * `language` - the language of the collection, if set
    * `local` - whether the collection originates from this instance
    * `sensitive` - whether the collection is marked as sensitive
    * `discoverable` - whether the collection has opted into discovery
      features
    * `tag` - the tag associated with the collection, if any
    * `created_at` - when the collection was created
    * `updated_at` - when the collection was last updated
    * `item_count` - number of items in the collection
    * `items` - list of `Hunter.Collection.Item`

  """

  @type t :: %__MODULE__{
          id: String.t(),
          account_id: String.t(),
          uri: String.t(),
          url: String.t() | nil,
          name: String.t(),
          description: String.t(),
          language: String.t() | nil,
          local: boolean,
          sensitive: boolean,
          discoverable: boolean,
          tag: map | nil,
          created_at: String.t(),
          updated_at: String.t(),
          item_count: non_neg_integer,
          items: [Hunter.Collection.Item.t()]
        }

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :account_id,
    :uri,
    :url,
    :name,
    :description,
    :language,
    :local,
    :sensitive,
    :discoverable,
    :tag,
    :created_at,
    :updated_at,
    :item_count,
    :items
  ]

  defmodule Item do
    @moduledoc """
    Collection item entity

    An account featured in a `Hunter.Collection`

    ## Fields

      * `id` - the ID of the collection item
      * `account_id` - the ID of the account this item represents
      * `state` - consent state of the item, one of: `pending`, `accepted`,
        `rejected`, `revoked`
      * `created_at` - when the item was added to the collection

    """

    @type t :: %__MODULE__{
            id: String.t(),
            account_id: String.t() | nil,
            state: String.t(),
            created_at: String.t()
          }

    @derive [Poison.Encoder]
    defstruct [:id, :account_id, :state, :created_at]
  end
end
