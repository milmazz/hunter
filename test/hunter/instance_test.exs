defmodule Hunter.InstanceTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Instance

  setup :verify_on_exit!

  test "verify instance information" do
    expect(Hunter.ApiMock, :instance_info, fn _conn ->
      %Instance{domain: "example.com", version: "4.3.8"}
    end)

    conn = Hunter.Client.new(base_url: "https://example.com", access_token: "123456")
    assert %Instance{domain: "example.com", version: "4.3.8"} = Instance.instance_info(conn)
  end
end
