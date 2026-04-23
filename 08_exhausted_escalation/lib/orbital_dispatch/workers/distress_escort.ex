defmodule OrbitalDispatch.Workers.DistressEscort do
  @moduledoc """
  Performs one escort launch for a distress incident.

  This worker is unique by `incident_id`, which lets duplicate reports from
  different relay chains collapse into one durable rescue obligation.
  """

  use Oban.Worker,
    queue: :escorts,
    max_attempts: 1,
    unique: [period: :infinity, keys: [:incident_id]]

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "incident_id" => _incident_id,
          "hull_id" => _hull_id,
          "distress_type" => _distress_type,
          "last_known_orbit" => _last_known_orbit,
          "distress_reported_at" => _distress_reported_at,
          "reported_via" => _reported_via
        }
      }) do
    :ok
  end
end
