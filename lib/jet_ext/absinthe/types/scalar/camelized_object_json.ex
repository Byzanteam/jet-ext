if Code.ensure_loaded?(Absinthe) do
  defmodule JetExt.Absinthe.Types.Scalar.CamelizedObjectJSON do
    @moduledoc """
    Serialized object JSON value.
    """

    use Absinthe.Schema.Notation

    scalar :camelized_object_json, name: "CamelizedObjectJSON" do
      description """
      The `CamelizedObjectJSON` scalar type represents arbitrary serialized object JSON,
      represented as UTF-8 character sequences with camelized keys.
      """

      serialize(&encode/1)
      parse(&decode/1)
    end

    # credo:disable-for-next-line JetCredo.Checks.ExplicitAnyType
    @spec decode(Absinthe.Blueprint.Input.String.t()) :: {:ok, term()} | :error
    @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
    defp decode(%Absinthe.Blueprint.Input.Null{}), do: {:ok, nil}

    defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
      case Jason.decode(value) do
        {:ok, %{} = map} ->
          {:ok, underscore(map)}

        _otherwise ->
          :error
      end
    end

    defp decode(_input), do: :error

    defp underscore(value) do
      iterate(value, fn key ->
        Macro.underscore(key)
      end)
    end

    defp encode(value) do
      value
      |> iterate(fn
        key when is_binary(key) ->
          camelize(key)

        key when is_atom(key) ->
          key |> Atom.to_string() |> camelize()
      end)
      |> Jason.encode!()
    end

    defp camelize(word) do
      {first, rest} = word |> Macro.camelize() |> String.split_at(1)
      String.downcase(first) <> rest
    end

    # iterate

    require Decimal

    defp iterate(value, _key_transform) when Decimal.is_decimal(value) do
      if Decimal.integer?(value) do
        Decimal.to_integer(value)
      else
        Decimal.to_float(value)
      end
    end

    defp iterate(value, _key_transform)
         when is_struct(value, NaiveDatetime)
         when is_struct(value, DateTime) do
      Jason.encode!(value)
    end

    defp iterate(value, key_transform) when is_map(value) do
      Map.new(value, fn {key, value} ->
        {key_transform.(key), iterate(value, key_transform)}
      end)
    end

    defp iterate([], _key_transform), do: []

    defp iterate([head | rest], key_transform) do
      [iterate(head, key_transform) | iterate(rest, key_transform)]
    end

    defp iterate(value, _key_transform), do: value
  end
end
