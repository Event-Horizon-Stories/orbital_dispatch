defmodule OrbitalDispatch.Application do
  @moduledoc """
  Starts the runtime for the lesson application.

  The supervision tree is intentionally small in chapter 1: a database repo and
  one Oban instance. That keeps the focus on the first durable obligation while
  still showing the shape of a normal OTP application.
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
