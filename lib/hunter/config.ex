defmodule Hunter.Config do
  @moduledoc """
  Hunter configuration.
  """

  @doc """
  Returns adapter module to do run API calls.

  ## Examples

      iex> Hunter.Config.hunter_api()
      Hunter.ApiMock

  """
  def hunter_api do
    Application.get_env(:hunter, :hunter_api, Hunter.Api.HTTPClient)
  end

  @doc """
  Returns the API base URL

  ## Examples

      iex> Hunter.Config.api_base_url()
      "https://mastodon.social"

  """
  def api_base_url do
    Application.get_env(:hunter, :api_base_url, "https://mastodon.social")
  end

  @doc """
  Returns the Hunter home directory

  ## Examples

      iex> Path.extname(Hunter.Config.home())
      ".hunter"

  """
  def home do
    home = System.get_env("HUNTER_HOME") || Application.get_env(:hunter, :home, "~/.hunter")
    Path.expand(home)
  end

  @doc """
  Returns HTTP options

      iex> Hunter.Config.http_options()
      []

  """
  def http_options do
    Application.get_env(:hunter, :http_options, [])
  end
end
