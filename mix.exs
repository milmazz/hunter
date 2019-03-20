defmodule Hunter.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hunter,
      version: "0.5.1-dev",
      elixir: "~> 1.6",
      docs: docs(),
      package: package(),
      source_url: "https://github.com/milmazz/hunter",
      description: "Elixir client for Mastodon, a GNU social-compatible micro-blogging service",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: ["lib"],
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :httpoison]]
  end

  defp deps do
    [
      {:httpoison, "~> 1.5"},
      {:poison, "~> 4.0"},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: :dev, runtime: false},
      {:mox, "~> 0.5", only: :test}
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
end
