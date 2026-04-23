defmodule OrbitalDispatch.Application do
  @moduledoc """
  Starts the supervision tree for the lesson app.

  The children stay the same even as the dispatch domain grows. That stability
  helps beginners see that new job types are usually data-and-module changes,
  not a complete OTP rewrite.
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
