defmodule Hunter.Error do
  @type t :: %__MODULE__{reason: any}

  defexception reason: nil

  def message(%__MODULE__{reason: reason}), do: inspect(reason)
end
