defmodule OrbitalDispatch.Oban do
  @moduledoc """
  Named Oban instance used throughout the lesson series.
  """

  use Oban, otp_app: :orbital_dispatch
end
