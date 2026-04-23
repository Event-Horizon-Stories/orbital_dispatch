defmodule OrbitalDispatch.Application do
  @moduledoc """
  Starts the supervision tree for the lesson application.

  The runtime stays compact in chapter 7: a repo plus one Oban instance. The
  new workflow behavior comes from added workers and queue rules, not from a
  different OTP shape.
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
