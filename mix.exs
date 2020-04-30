defmodule BambooSes.MixProject do
  use Mix.Project

  def project do
    [
      app: :bamboo_ses,
      elixir: "~> 1.6",
      description: description(),
      deps: deps(),
      docs: docs(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/kalys/bamboo_ses",
      version: "0.1.5"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_aws_ses, "~> 2.1.1"},
      {:bamboo, "~> 1.0"},
      {:mail, github: "DockYard/elixir-mail"},
      {:mox, "~> 0.3", only: :test},
      {:credo, "~> 0.9.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.14", only: :dev}
    ]
  end

  defp description do
    "AWS SES adapter for Bamboo"
  end

  defp docs do
    [main: "readme", extras: ["README.md"]]
  end

  defp package do
    [
      maintainers: ["Kalys Osmonov <kalys@osmonov.com>"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/kalys/bamboo_ses"}
    ]
  end
end
