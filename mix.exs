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
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ],
      dialyzer: [
        plt_add_apps: [:mix, :phoenix, :plug],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      package: package(),
      deps: deps(),
      docs: docs(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Required dependencies
      {:plug, "~> 1.13"},
      {:telemetry, "~> 1.1"},
      {:xxh3, "~> 0.3.2"},
      {:cuckoo_filter, "~> 0.3.1"},

      # Development dependencies
      {:ex_doc, "~> 0.29.0", only: :dev},
      {:doctor, "~> 0.20.0", only: :dev},
      {:credo, "~> 1.6", only: :dev},
      {:excoveralls, "~> 0.15.3", only: :test, runtime: false},
      {:dialyxir, "~> 1.2.0", only: :dev, runtime: false},
      {:git_hooks, "~> 0.7.3", only: [:test, :dev], runtime: false}
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

  defp aliases do
    [
      docs: ["docs", &copy_files/1]
    ]
  end

  defp copy_files(_) do
    # Set up directory structure
    File.mkdir_p!("./doc/guides/images")

    # Copy over image files
    "./guides/images/"
    |> File.ls!()
    |> Enum.each(fn image_file ->
      File.cp!("./guides/images/#{image_file}", "./doc/guides/images/#{image_file}")
    end)
  end
end
