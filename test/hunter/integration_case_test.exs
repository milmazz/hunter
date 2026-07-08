defmodule Hunter.IntegrationCaseTest do
  use ExUnit.Case, async: true

  @tag timeout: 2_000
  test "eventually/2 with attempts <= 1 runs the function exactly once" do
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    assert_raise RuntimeError, "nope", fn ->
      Hunter.IntegrationCase.eventually(
        fn ->
          Agent.update(agent, &(&1 + 1))
          raise "nope"
        end,
        0
      )
    end

    assert Agent.get(agent, & &1) == 1
  end
end
