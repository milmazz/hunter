defmodule Hunter.Mixfile do
  use Mix.Project

  def project do
    [app: :hunter,
     version: "0.4.0",
     elixir: "~> 1.3",
     docs: docs(),
     package: package(),
     source_url: "https://github.com/milmazz/hunter",
     description: "Elixir client for Mastodon, a GNU social-compatible micro-blogging service",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :httpoison]]
  end

  defp deps do
    [{:httpoison, "~> 0.10.0"},
     {:poison, "~> 3.0"},
     {:ex_doc, "~> 0.14", only: :dev, runtime: false}]
  end

  defp package do
    [licenses: ["Apache 2.0"],
     maintainers: ["Milton Mazzarri"],
     links: %{"GitHub" => "https://github.com/milmazz/hunter"}]
  end

  defp docs do
    [extras: ["README.md": [title: "README"],
              "CONTRIBUTING.md": [title: "How to contribute"],
              "CODE_OF_CONDUCT.md": [title: "Code of Conduct"],
              "CHANGELOG.md": [title: "Changelog"]],
     main: "readme"]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
