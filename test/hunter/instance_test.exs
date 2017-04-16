defmodule Hunter.InstanceTest do
  use ExUnit.Case, async: true

  alias Hunter.Instance

  setup do
    [conn: Hunter.Client.new([base_url: "https://example.com", bearer_token: "123456"])]
  end

  test "verify instance information", %{conn: conn} do
    assert %Instance{uri: "social.lou.lt"} = Instance.instance_info(conn)
  end
end
