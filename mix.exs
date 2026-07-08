defmodule Hunter.Mixfile do
  use Mix.Project

  @version "0.6.0"
  @source_url "https://github.com/milmazz/hunter"

  def project do
    [
      app: :hunter,
      version: @version,
      elixir: "~> 1.15",
      docs: docs(),
      package: package(),
      source_url: @source_url,
      description: "Elixir client for the Mastodon API",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
        plt_file: {:no_warn, "priv/plts/project.plt"},
        flags: [:error_handling, :underspecs]
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:req, "~> 0.6"},
      {:poison, "~> 6.0"},
      {:plug, "~> 1.16", only: :test},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:mox, "~> 1.0", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["Apache-2.0"],
      maintainers: ["Milton Mazzarri"],
      links: %{"GitHub" => @source_url}
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
      main: "readme",
      source_ref: "v#{@version}"
    ]
  end
end
