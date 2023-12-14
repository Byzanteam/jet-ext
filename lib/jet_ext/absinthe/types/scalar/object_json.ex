if Code.ensure_loaded?(Absinthe) do
  defmodule JetExt.Absinthe.Types.Scalar.ObjectJSON do
    @moduledoc false

    use Absinthe.Schema.Notation

    scalar :object_json, name: "ObjectJSON" do
      description """
      The `ObjectJSON` scalar type represents arbitrary JSON string data, represented as UTF-8
      character sequences.
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

    defp encode(value) do
      value
      |> iterate()
      |> Jason.encode!()
    end

    # iterate

    require Decimal

    defp iterate(value) when Decimal.is_decimal(value) do
      if Decimal.integer?(value) do
        Decimal.to_integer(value)
      else
        Decimal.to_float(value)
      end
    end

    defp iterate(value)
         when is_struct(value, NaiveDateTime)
         when is_struct(value, DateTime) do
      value
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
