defmodule Hunter.Api.HTTPClient do
  @moduledoc """
  HTTP Client for Hunter
  """

  alias Hunter.Api.Request

  def instance_info(conn) do
    Request.request!(conn, :get, "/api/v2/instance", :instance)
  end

  def report(conn, account_id, status_ids, comment) do
    payload = %{
      account_id: account_id,
      status_ids: status_ids,
      comment: comment
    }

    Request.request!(conn, :post, "/api/v1/reports", :report, payload)
  end

  def blocked_domains(conn, options) do
    Request.request!(conn, :get, "/api/v1/domain_blocks", nil, options)
  end

  def block_domain(conn, domain) do
    Request.request!(conn, :post, "/api/v1/domain_blocks", :empty, %{domain: domain})
  end

  def unblock_domain(conn, domain) do
    Request.request!(conn, :delete, "/api/v1/domain_blocks", :empty, %{domain: domain})
  end
end
