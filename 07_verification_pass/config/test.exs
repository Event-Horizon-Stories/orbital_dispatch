import Config

config :logger, level: :warning

config :orbital_dispatch, OrbitalDispatch.Repo,
  database: Path.expand("../orbital_dispatch_test.db", __DIR__),
  pool_size: 1

config :orbital_dispatch, OrbitalDispatch.Oban,
  testing: :manual,
  queues: false,
  plugins: false
