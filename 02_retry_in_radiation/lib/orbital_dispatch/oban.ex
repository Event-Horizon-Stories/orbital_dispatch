defmodule OrbitalDispatch.Oban do
  @moduledoc """
  Named Oban instance for the lesson runtime.

  The wrapper gives the rest of the code one consistent place to enqueue and
  drain jobs across every chapter.
  """

  use Oban, otp_app: :orbital_dispatch
end
