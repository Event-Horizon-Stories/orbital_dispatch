defmodule OrbitalDispatch.Oban do
  @moduledoc """
  Named Oban instance for the lesson runtime.
  """

  use Oban, otp_app: :orbital_dispatch
end
