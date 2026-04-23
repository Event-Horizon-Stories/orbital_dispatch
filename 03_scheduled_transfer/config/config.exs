import Config

config :orbital_dispatch,
  ecto_repos: [OrbitalDispatch.Repo]

config :orbital_dispatch, OrbitalDispatch.Repo,
  database: Path.expand("../orbital_dispatch_dev.db", __DIR__),
  pool_size: 5

config :orbital_dispatch, OrbitalDispatch.Oban,
  engine: Oban.Engines.Lite,
  repo: OrbitalDispatch.Repo,
  queues: [
    repairs: [limit: 5, paused: true],
    launches: [limit: 5, paused: true],
    transfers: [limit: 5, paused: true]
  ],
  plugins: []

import_config "#{config_env()}.exs"
