import Config

patrol_crontab = [
  {"* * * * *", OrbitalDispatch.Workers.CorridorPatrol,
   args: %{
     route_id: "outer transfer routes",
     checkpoint: "ice-shadow repeater chain",
     risk: "micrometeoroid scoring and relay ice accretion"
   },
   queue: :patrols,
   max_attempts: 1}
]

config :orbital_dispatch,
  ecto_repos: [OrbitalDispatch.Repo]

config :orbital_dispatch, :patrol_crontab, patrol_crontab

config :orbital_dispatch, OrbitalDispatch.Repo,
  database: Path.expand("../orbital_dispatch_dev.db", __DIR__),
  pool_size: 5

config :orbital_dispatch, OrbitalDispatch.Oban,
  engine: Oban.Engines.Lite,
  repo: OrbitalDispatch.Repo,
  queues: [
    repairs: [limit: 5, paused: true],
    launches: [limit: 5, paused: true],
    transfers: [limit: 5, paused: true],
    patrols: [limit: 5, paused: true],
    escorts: [limit: 5, paused: true],
    corridors: [limit: 5, paused: true],
    verifications: [limit: 5, paused: true]
  ],
  plugins: [
    {Oban.Plugins.Cron, crontab: patrol_crontab}
  ]

import_config "#{config_env()}.exs"
