defmodule OrbitalDispatch.Storage do
  @moduledoc false

  alias OrbitalDispatch.Repo

  def ensure_ready! do
    ensure_storage!()

    {:ok, pid} = Repo.start_link(pool_size: 1)

    try do
      Ecto.Migrator.run(Repo, migrations_path(), :up, all: true)
    after
      GenServer.stop(pid)
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
end
