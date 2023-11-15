defmodule JetExt.MixProject do
  use Mix.Project

  def project do
    [
      app: :jet_ext,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        plt_add_apps: [:urn, :plug, :absinthe]
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
      {:ecto, ">= 3.9.5 and < 4.0.0"},
      {:urn, "~> 1.0", optional: true},
      {:plug, "~> 1.14", optional: true},
      {:absinthe, "~> 1.7", optional: true},
      {:absinthe_relay, "~> 1.5", optional: true},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp elixirc_paths(:prod), do: ["lib"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
