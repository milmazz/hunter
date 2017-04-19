defmodule Hunter.Config do
  @moduledoc false

  @hunter_api Application.get_env(:hunter, :hunter_api, Hunter.Api.HTTPClient)

  def hunter_api do
   @hunter_api 
  end
end
