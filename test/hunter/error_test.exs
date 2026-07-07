defmodule Hunter.ErrorTest do
  use ExUnit.Case, async: true

  test "message renders the reason" do
    error = %Hunter.Error{reason: :econnrefused}

    assert Exception.message(error) == ":econnrefused"
  end

  test "raising with a reason" do
    assert_raise Hunter.Error, ~s("boom"), fn ->
      raise Hunter.Error, reason: "boom"
    end
  end
end
