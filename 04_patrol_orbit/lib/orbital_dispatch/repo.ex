defmodule OrbitalDispatch.Repo do
  use Ecto.Repo, otp_app: :orbital_dispatch, adapter: Ecto.Adapters.SQLite3
end
