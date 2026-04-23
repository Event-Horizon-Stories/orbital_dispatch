defmodule OrbitalDispatch.Storage do
  @moduledoc """
  Prepares local SQLite storage before tests or interactive experiments run.

  The repo only performs setup when asked, which mirrors the safer idea that
  schema preparation should be deliberate rather than a side effect of booting
  the app.
  """

  alias OrbitalDispatch.Repo

  def ensure_ready! do
    ensure_storage!()

    # Start a temporary repo only when migrations need one.
    {pid, started_here?} = ensure_repo_started!()

    try do
      Ecto.Migrator.run(Repo, migrations_path(), :up, all: true)
    after
      if started_here? do
        GenServer.stop(pid)
      end
    end
  end

  defp ensure_storage! do
    case Repo.__adapter__().storage_up(Repo.config()) do
      :ok -> :ok
      {:error, :already_up} -> :ok
      {:error, reason} -> raise "could not prepare sqlite storage: #{inspect(reason)}"
    end
  end

  defp migrations_path do
    Application.app_dir(:orbital_dispatch, "priv/repo/migrations")
  end

  defp ensure_repo_started! do
    case Repo.start_link(pool_size: 1) do
      {:ok, pid} -> {pid, true}
      {:error, {:already_started, pid}} -> {pid, false}
    end
  end
end
