defmodule Hunter.Config do
  @moduledoc false

  @hunter_api Application.get_env(:hunter, :hunter_api, Hunter.Api.HTTPClient)
  @api_base_url "https://mastodon.social"

  def hunter_api() do
    @hunter_api
  end

  def api_base_url() do
    @api_base_url
  end

  def home() do
    Path.expand(System.get_env("HUNTER_HOME") || "~/.hunter")
  end
end
