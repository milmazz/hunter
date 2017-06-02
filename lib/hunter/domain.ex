defmodule Hunter.Domain do
  @moduledoc """
  Domain blocks
  """

  @hunter_api Hunter.Config.hunter_api()

  @doc """
  Fetch user's blocked domains

  ## Parameters

    * `conn` - connection credentials
    * `options` - option list

  ## Options

    * `max_id` - get a list of blocks with id less than or equal this value
    * `since_id` - get a list of blocks with id greater than this value
    * `limit` - maximum number of blocks to get, default: 40, max: 80

  """
  @spec blocked_domains(Hunter.Client.t, Keyword.t) :: list
  def blocked_domains(conn, options \\ []) do
    @hunter_api.blocked_domains(conn, options)
  end

  @doc """
  Block a domain

  ## Parameters

    * `conn` - connection credentials
    * `domain` - domain to block

  """
  @spec block_domain(Hunter.Client.t, String.t) :: boolean
  def block_domain(conn, domain) do
    @hunter_api.block_domain(conn, domain)
  end

  @doc """
  Unblock a domain

  ## Parameters

    * `conn` - connection credentials
    * `domain` - domain to unblock

  """
  @spec unblock_domain(Hunter.Client.t, String.t) :: boolean
  def unblock_domain(conn, domain) do
    @hunter_api.unblock_domain(conn, domain)
  end
end
