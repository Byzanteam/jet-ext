defmodule JetExt.MixProject do
  use Mix.Project

  def project do
    [
      app: :jet_ext,
      version: "0.2.2",
      elixir: "~> 1.14",
      description: "The extended tools for the Jet Team.",
      source_url: "https://github.com/Byzanteam/jet-ext",
      package: [
        name: "jet_ext",
        licenses: ["MIT"],
        files: ~w(lib mix.exs mix.lock .tool-versions README.md),
        links: %{
          "GitHub" => "https://github.com/Byzanteam/jet-ext"
        }
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        plt_add_apps: [:urn, :plug, :absinthe, :absinthe_relay]
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
      {:typed_struct, "~> 0.3.0"},
      {:postgrex, "~> 0.18.0", optional: true},
      {:urn, "~> 1.0", optional: true},
      {:plug, "~> 1.14", optional: true},
      {:absinthe, "~> 1.7", optional: true},
      {:absinthe_relay, "~> 1.5", optional: true},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:jason, "~> 1.4"},
      {:mimic, "~> 1.7", only: :test},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:polymorphic_embed, "~> 4.1.1", only: :test}
    ]
  end

  defp elixirc_paths(:prod), do: ["lib"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
