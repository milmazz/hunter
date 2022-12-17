defmodule Hunter.Mixfile do
  use Mix.Project

  @version "0.5.2-dev"

  def project do
    [
      app: :hunter,
      version: @version,
      elixir: "~> 1.8",
      docs: docs(),
      package: package(),
      source_url: "https://github.com/milmazz/hunter",
      description: "Elixir client for Mastodon, a GNU social-compatible micro-blogging service",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [
      extra_applications: [:logger],
      mod: {Hunter, []}
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:finch, "~> 0.2"},
      {:mox, "~> 1.0", only: :test},
      {:poison, "~> 5.0"}
    ]
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      maintainers: ["Milton Mazzarri"],
      links: %{"GitHub" => "https://github.com/milmazz/hunter"}
    ]
  end

  defp docs do
    [
      extras: [
        "README.md": [title: "README"],
        "CONTRIBUTING.md": [title: "How to contribute"],
        "CODE_OF_CONDUCT.md": [title: "Code of Conduct"],
        "CHANGELOG.md": [title: "Changelog"]
      ],
      main: "readme"
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mix, :ex_unit],
      check_plt: true,
      flags: [:unmatched_returns, :error_handling, :no_opaque]
    ]
  end
end
