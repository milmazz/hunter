defmodule Hunter.ReportTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Report

  @conn Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")

  setup :verify_on_exit!

  test "reports an account" do
    expect(Hunter.ApiMock, :report, fn %Hunter.Client{}, 8039, [153_452], "spam" ->
      %Report{id: "48915", action_taken: false}
    end)

    assert %Report{id: "48915"} = Report.report(@conn, 8039, [153_452], "spam")
  end
end
