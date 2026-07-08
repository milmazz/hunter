defmodule Hunter.List do
  @moduledoc """
  List entity

  A list of some users that the authenticated user follows

  ## Fields

    * `id` - the ID of the list
    * `title` - the user-defined title of the list
    * `replies_policy` - which replies should be shown in the list, one of:
      `followed`, `list`, `none`
    * `exclusive` - whether members of the list are removed from the home
      timeline

  """
  alias Hunter.Api.HTTPClient

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          replies_policy: String.t(),
          exclusive: boolean | nil
        }

  @derive [Poison.Encoder]
  defstruct [:id, :title, :replies_policy, :exclusive]

  @doc """
  Retrieve all lists the user owns

  ## Parameters

    * `conn` - connection credentials

  """
  @spec lists(Hunter.Client.t()) :: [Hunter.List.t()]
  def lists(conn) do
    HTTPClient.lists(conn)
  end

  @doc """
  Retrieve a list

  ## Parameters

    * `conn` - connection credentials
    * `id` - list identifier

  """
  @spec list(Hunter.Client.t(), non_neg_integer) :: Hunter.List.t()
  def list(conn, id) do
    HTTPClient.list(conn, id)
  end

  @doc """
  Create a new list

  ## Parameters

    * `conn` - connection credentials
    * `title` - the title of the list
    * `options` - option list

  ## Options

    * `replies_policy` - which replies should be shown in the list, one of:
      `followed`, `list`, `none`; default: `list`
    * `exclusive` - whether members of the list are removed from the home
      timeline

  """
  @spec create_list(Hunter.Client.t(), String.t(), Keyword.t()) :: Hunter.List.t()
  def create_list(conn, title, options \\ []) do
    HTTPClient.create_list(conn, title, options)
  end

  @doc """
  Update a list

  ## Parameters

    * `conn` - connection credentials
    * `id` - list identifier
    * `options` - option list

  ## Options

    * `title` - the new title of the list
    * `replies_policy` - which replies should be shown in the list, one of:
      `followed`, `list`, `none`
    * `exclusive` - whether members of the list are removed from the home
      timeline

  """
  @spec update_list(Hunter.Client.t(), non_neg_integer, Keyword.t()) :: Hunter.List.t()
  def update_list(conn, id, options) do
    HTTPClient.update_list(conn, id, options)
  end

  @doc """
  Delete a list

  ## Parameters

    * `conn` - connection credentials
    * `id` - list identifier

  """
  @spec destroy_list(Hunter.Client.t(), non_neg_integer) :: boolean
  def destroy_list(conn, id) do
    HTTPClient.destroy_list(conn, id)
  end

  @doc """
  Retrieve the accounts in a list

  ## Parameters

    * `conn` - connection credentials
    * `id` - list identifier
    * `options` - option list

  ## Options

    * `max_id` - get a list of accounts with id less than or equal this value
    * `since_id` - get a list of accounts with id greater than this value
    * `limit` - maximum number of accounts to get, default: 40; set to 0 to
      get all accounts in the list

  """
  @spec list_accounts(Hunter.Client.t(), non_neg_integer, Keyword.t()) :: [Hunter.Account.t()]
  def list_accounts(conn, id, options \\ []) do
    HTTPClient.list_accounts(conn, id, options)
  end

  @doc """
  Add accounts to a list; the user must be following each of them

  ## Parameters

    * `conn` - connection credentials
    * `id` - list identifier
    * `account_ids` - account identifiers to add

  """
  @spec add_accounts_to_list(Hunter.Client.t(), non_neg_integer, [non_neg_integer]) :: boolean
  def add_accounts_to_list(conn, id, account_ids) do
    HTTPClient.add_accounts_to_list(conn, id, account_ids)
  end

  @doc """
  Remove accounts from a list

  ## Parameters

    * `conn` - connection credentials
    * `id` - list identifier
    * `account_ids` - account identifiers to remove

  """
  @spec remove_accounts_from_list(Hunter.Client.t(), non_neg_integer, [non_neg_integer]) ::
          boolean
  def remove_accounts_from_list(conn, id, account_ids) do
    HTTPClient.remove_accounts_from_list(conn, id, account_ids)
  end

  @doc """
  Retrieve the user's lists that contain a given account

  ## Parameters

    * `conn` - connection credentials
    * `account_id` - account identifier

  """
  @spec account_lists(Hunter.Client.t(), non_neg_integer) :: [Hunter.List.t()]
  def account_lists(conn, account_id) do
    HTTPClient.account_lists(conn, account_id)
  end
end
