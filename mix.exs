defmodule BambooSes.MixProject do
  use Mix.Project

  @source_url "https://github.com/kalys/bamboo_ses"
  @version "0.5.0"

  def project do
    [
      app: :bamboo_ses,
      elixir: "~> 1.6",
      version: @version,
      deps: deps(),
      docs: docs(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_aws, "~> 2.4"},
      {:bamboo, "~> 2.0"},
      {:jason, "~> 1.1"},
      {:mox, "~> 1.0", only: :test},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "CONTRIBUTING.md": [title: "Contributing"],
        "CODE_OF_CONDUCT.md": [title: "Code of Conduct"],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      formatters: ["html"]
    ]
  end

  defp package do
    [
      description: "AWS SES adapter for Bamboo",
      maintainers: ["Kalys Osmonov <kalys@osmonov.com>"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/kalys/bamboo_ses"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
