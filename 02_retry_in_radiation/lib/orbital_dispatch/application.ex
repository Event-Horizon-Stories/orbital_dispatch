defmodule OrbitalDispatch.Application do
  @moduledoc """
  Starts the lesson application's supervision tree.

  The shape is still intentionally small: a repo plus one Oban instance. The
  runtime stays stable while the dispatch domain grows from one queue to many.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OrbitalDispatch.Repo,
      {OrbitalDispatch.Oban, []}
    ]

    opts = [strategy: :one_for_one, name: OrbitalDispatch.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
