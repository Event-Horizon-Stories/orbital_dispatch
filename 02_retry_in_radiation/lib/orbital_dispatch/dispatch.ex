defmodule OrbitalDispatch.Dispatch do
  @moduledoc false

  alias OrbitalDispatch.Dispatch.{Launches, Repairs}

  defdelegate dispatch_cargo_launch(attrs), to: Launches
  defdelegate launch_attempts(), to: Launches
  defdelegate pending_repairs(), to: Repairs
  defdelegate report_relay_fracture(attrs), to: Repairs
end
