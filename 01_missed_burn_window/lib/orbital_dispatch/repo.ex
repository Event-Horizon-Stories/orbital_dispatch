defmodule OrbitalDispatch.Repo do
  @moduledoc """
  Ecto repo for the lesson application's SQLite database.

  Every chapter keeps the same repo name so the runtime shape stays stable while
  the dispatch domain grows.
  """

  use Ecto.Repo, otp_app: :orbital_dispatch, adapter: Ecto.Adapters.SQLite3
end
