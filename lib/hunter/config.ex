defmodule Hunter.Config do
  @moduledoc """
  Hunter configuration.
  """

  def hunter_api do
    Application.get_env(:hunter, :hunter_api, Hunter.Api.HTTPClient)
  end

  def api_base_url do
    Application.get_env(:hunter, :api_base_url, "https://mastodon.social")
  end

  def home do
    Path.expand(System.get_env("HUNTER_HOME") || "~/.hunter")
  end
end
