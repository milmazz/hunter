defmodule Hunter.Filter do
  @moduledoc """
  Filter entity

  A server-side filter group (v2 filters)

  ## Fields

    * `id` - the ID of the filter
    * `title` - the title given by the user to the filter
    * `context` - contexts in which the filter is applied, list of:
      `home`, `notifications`, `public`, `thread`, `account`
    * `expires_at` - when the filter should no longer be applied, `nil` when
      it never expires
    * `filter_action` - action to take when a status matches the filter, one
      of: `warn`, `hide`, `blur`
    * `keywords` - list of `Hunter.FilterKeyword`, the keywords grouped under
      this filter
    * `statuses` - list of `Hunter.FilterStatus`, the statuses grouped under
      this filter

  """

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          context: [String.t()],
          expires_at: String.t() | nil,
          filter_action: String.t(),
          keywords: [Hunter.FilterKeyword.t()],
          statuses: [Hunter.FilterStatus.t()]
        }

  @derive [Poison.Encoder]
  defstruct [:id, :title, :context, :expires_at, :filter_action, :keywords, :statuses]
end
