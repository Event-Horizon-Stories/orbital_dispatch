defmodule OrbitalDispatch.MixProject do
  use Mix.Project

  def project do
    [
      app: :orbital_dispatch,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [precommit: :test],
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {OrbitalDispatch.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.13"},
      {:ecto_sqlite3, "~> 0.22"},
      {:jason, "~> 1.4"},
      {:oban, "~> 2.20"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      precommit: ["format", "test"]
    ]
  end
end
