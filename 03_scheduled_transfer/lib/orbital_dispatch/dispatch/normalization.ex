defmodule OrbitalDispatch.Dispatch.Normalization do
  @moduledoc """
  Shared helpers for shaping interactive input into queue-ready values.
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
    # Let examples stay flexible by accepting either atom or string keys.
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

  def normalize_positive_integer(value, _field) when is_integer(value) and value > 0,
    do: {:ok, value}

  def normalize_positive_integer(value, field) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed > 0 -> {:ok, parsed}
      _ -> {:error, {:invalid_positive_integer, field, value}}
    end
  end

  def normalize_positive_integer(value, field),
    do: {:error, {:invalid_positive_integer, field, value}}
end
