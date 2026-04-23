defmodule OrbitalDispatch.Repo do
  @moduledoc """
  Ecto repo for the lesson's SQLite database.
  """

  use Ecto.Repo, otp_app: :orbital_dispatch, adapter: Ecto.Adapters.SQLite3
end
