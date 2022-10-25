defmodule Phx2Ban.MixProject do
  use Mix.Project

  def project do
    [
      app: :phx_2_ban,
      version: "0.1.0-beta",
      elixir: "~> 1.14",
      name: "Phx2Ban",
      source_url: "https://github.com/akoutmos/phx_2_ban",
      homepage_url: "https://hex.pm/packages/phx_2_ban",
      description: "Block access to your application from IP addresses making malicious requests",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs()
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
      # Production dependencies
      {:plug, "~> 1.13"},
      {:telemetry, "~> 1.1"},
      {:xxh3, "~> 0.3.2"},
      {:cuckoo_filter, "~> 0.3.1"},

      # Development dependencies
      {:ex_doc, "~> 0.29.0", only: :dev}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "master",
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      name: "phx_2_ban",
      files: ~w(lib mix.exs README.md),
      licenses: ["MIT"],
      maintainers: ["Alex Koutmos"],
      links: %{
        "GitHub" => "https://github.com/akoutmos/phx_2_ban",
        "Sponsor" => "https://github.com/sponsors/akoutmos"
      }
    ]
  end
end
