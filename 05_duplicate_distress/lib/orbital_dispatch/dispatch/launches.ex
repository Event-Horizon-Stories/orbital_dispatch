defmodule OrbitalDispatch.Dispatch.Launches do
  @moduledoc """
  Owns cargo-launch creation and retry inspection.

  This module is carried into chapter 5 unchanged so duplicate-distress work can
  be added without disturbing the earlier retry story.
  """

  alias OrbitalDispatch.Dispatch.{JobView, Normalization}
  alias OrbitalDispatch.Workers.CargoLaunch

  @required_fields [:drone_id, :cargo_id, :corridor, :launch_window_opens_at]
  @visible_states ["available", "scheduled", "retryable", "executing", "discarded"]

  def dispatch_cargo_launch(attrs) when is_map(attrs) do
    with {:ok, normalized} <- normalize_cargo_launch(attrs) do
      normalized
      |> CargoLaunch.new()
      |> OrbitalDispatch.Oban.insert()
    end
  end

  def launch_attempts do
    JobView.list(CargoLaunch, @visible_states, &JobView.launch_snapshot/1)
  end

  defp normalize_cargo_launch(attrs) do
    normalized = Normalization.required_values(attrs, @required_fields)
    missing_fields = Normalization.missing_fields(normalized)
    clears_on_attempt = Normalization.fetch_value(attrs, :guidance_noise_clears_on_attempt) || 1

    case missing_fields do
      [] ->
        with {:ok, launch_window_opens_at} <-
               Normalization.normalize_timestamp(normalized.launch_window_opens_at),
             {:ok, clears_on_attempt} <-
               Normalization.normalize_positive_integer(
                 clears_on_attempt,
                 :guidance_noise_clears_on_attempt
               ) do
          # Job args should stay JSON-friendly because Oban persists them.
          {:ok,
           %{
             drone_id: normalized.drone_id,
             cargo_id: normalized.cargo_id,
             corridor: normalized.corridor,
             launch_window_opens_at: DateTime.to_iso8601(launch_window_opens_at),
             guidance_noise_clears_on_attempt: clears_on_attempt
           }}
        end

      _ ->
        {:error, {:missing_fields, missing_fields}}
    end
  end
end
