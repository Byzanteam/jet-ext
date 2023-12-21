if Code.ensure_loaded?(Absinthe) do
  defmodule JetExt.Absinthe.Types.Scalar.ObjectJSON do
    @moduledoc false

    use Absinthe.Schema.Notation

    scalar :object_json, name: "ObjectJSON" do
      description """
      The `ObjectJSON` scalar type represents arbitrary JSON object data, represented as UTF-8 character sequences.

      This type is specifically tailored to work with JSON objects at the root level, ensuring that the top-level element of the JSON structure is always a JSON object.
      It does not support other JSON types (like arrays or primitives) as the root element.
      This makes it ideal for scenarios where JSON data is structured as key-value pairs at the highest level."
      """

      serialize(&encode/1)
      parse(&decode/1)
    end

    @spec decode(Absinthe.Blueprint.Input.String.t()) :: {:ok, map()} | :error
    @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
    defp decode(%Absinthe.Blueprint.Input.Null{}), do: {:ok, nil}

    defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
      case Jason.decode(value) do
        {:ok, %{} = data} -> {:ok, data}
        _otherwise -> :error
      end
    end

    defp decode(_input), do: :error

    defp encode(value) when is_map(value) and not is_struct(value) do
      value
      |> iterate()
      |> Jason.encode!()
    end

    defp encode(_value) do
      raise Absinthe.SerializationError
    end

    # iterate

    if Code.ensure_loaded?(Decimal) do
      require Decimal

      defp iterate(value) when Decimal.is_decimal(value) do
        if Decimal.integer?(value) do
          Decimal.to_integer(value)
        else
          Decimal.to_float(value)
        end
      end
    end

    defp iterate(value)
         when is_struct(value, NaiveDateTime)
         when is_struct(value, DateTime) do
      value
    end

    defp iterate(value) when is_struct(value) do
      raise Absinthe.SerializationError
    end

    defp iterate(value) when is_map(value) do
      Map.new(value, fn {key, val} ->
        {key, iterate(val)}
      end)
    end

    defp iterate([]), do: []

    defp iterate([head | rest]) do
      [iterate(head) | iterate(rest)]
    end

    defp iterate(value), do: value
  end
end
