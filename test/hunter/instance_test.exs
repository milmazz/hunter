defmodule Hunter.InstanceTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Instance

  setup :verify_on_exit!

  test "verify instance information" do
    expect(Hunter.ApiMock, :instance_info, fn _conn ->
      %Instance{uri: "social.lou.lt"}
    end)

    conn = Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")
    assert %Instance{uri: "social.lou.lt"} = Instance.instance_info(conn)
  end
end
