defmodule OrbitalDispatch.Workers.ReplacementTransfer do
  @moduledoc false

  use Oban.Worker, queue: :transfers, max_attempts: 1

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "part_id" => _part_id,
          "source_bay" => _source_bay,
          "destination_hull" => _destination_hull,
          "docking_window_opens_at" => _docking_window_opens_at
        }
      }) do
    :ok
  end
end
