defmodule Phx2Ban.MixProject do
  use Mix.Project

  def project do
    [
      app: :phx_2_ban,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:plug, "~> 1.13"},
      {:telemetry, "~> 1.1"},
      {:xxh3, "~> 0.3.2"},
      {:cuckoo_filter, "~> 0.3.1"}
    ]
  end
end
