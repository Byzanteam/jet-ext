defmodule JetExt.Absinthe.OneOf.TestSchema do
  @moduledoc false

  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  @prototype_schema JetExt.Absinthe.OneOf.SchemaProtoType

  input_object :one_of_test_type do
    directive :one_of

    private(:input_modifier, :with, {__MODULE__, :switch_kv, []})

    field :field_a, :string
    field :field_b, :string
    field :field_c, :string
  end

  query name: "Query" do
    field :placeholder, :string do
      resolve fn _args, _resolution -> raise "Never be called." end
    end
  end

  mutation name: "Mutation" do
    payload field(:one_of_test_mutation) do
      input do
        field :foo, non_null(:one_of_test_type)
      end

      output do
        field :bar, :string
      end

      middleware JetExt.Absinthe.OneOf.Middleware.InputModifier
      resolve &one_of_test_mutation/2
    end
  end

  defp one_of_test_mutation(args, _resolution) do
    case Enum.to_list(args.foo) do
      [{_key, value}] -> {:ok, %{bar: value}}
      _otherwise -> {:error, "invalid arguments"}
    end
  end

  @spec switch_kv(data :: map(), input_object) :: {map(), input_object}
        when input_object: Absinthe.Blueprint.Input.Object.t()
  def switch_kv(data, input_object) do
    input_object =
      Map.update!(input_object, :schema_node, fn schema_node ->
        Map.update!(schema_node, :__private__, &Keyword.delete(&1, :input_modifier))
      end)

    case Enum.to_list(data) do
      [{k, v}] ->
        {%{v => to_string(k)}, input_object}

      _otherwise ->
        {data, input_object}
    end
  end
end
