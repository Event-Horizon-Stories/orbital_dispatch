defmodule OrbitalDispatch.Dispatch.Normalization do
  @moduledoc """
  Small input-shaping helpers shared by the dispatch submodules.

  The lessons accept maps from tests and `iex`, where keys may be atoms or
  strings. Centralizing that normalization keeps the dispatch modules focused on
  queue behavior instead of repetitive data cleanup.
  """

  def required_values(attrs, fields) do
    Enum.reduce(fields, %{}, fn field, acc ->
      Map.put(acc, field, fetch_value(attrs, field))
    end)
  end

  def missing_fields(values) do
    values
    |> Enum.filter(fn {_field, value} -> is_nil(value) or value == "" end)
    |> Enum.map(&elem(&1, 0))
  end

  def fetch_value(attrs, field) do
    # Accept either atom or string keys so examples stay friendly in `iex`.
    Map.get(attrs, field) || Map.get(attrs, Atom.to_string(field))
  end

  def normalize_timestamp(%DateTime{} = value), do: {:ok, DateTime.truncate(value, :second)}

  def normalize_timestamp(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> {:ok, DateTime.truncate(datetime, :second)}
      {:error, reason} -> {:error, {:invalid_timestamp, value, reason}}
    end
  end

  def normalize_timestamp(value), do: {:error, {:invalid_timestamp, value, :unsupported}}
end
