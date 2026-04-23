defmodule OrbitalDispatch.Oban do
  @moduledoc """
  The lesson's named Oban instance.

  Keeping Oban behind a small wrapper lets the rest of the code call
  `OrbitalDispatch.Oban.insert/1` and `drain_queue/1` without repeating config
  details.
  """

  use Oban, otp_app: :orbital_dispatch
end
