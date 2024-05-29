defmodule JetExt.Absinthe.OneOf.TestSchema do
  @moduledoc false

  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  @prototype_schema JetExt.Absinthe.OneOf.SchemaProtoType

  defmodule A do
    defstruct [:a]
  end

  defmodule B do
    defstruct [:b]
  end

  input_object :one_of_test_type do
    directive :one_of

    private(:input_modifier, :with, {__MODULE__, :switch_kv, []})

    field :field_a, :string
    field :field_b, :string
    field :field_c, :string
  end

  input_object :struct_a do
    field :a, :string
  end

  input_object :struct_b do
    field :b, :string
  end

  input_object :one_of_test_struct_type do
    directive :one_of

    private(:input_modifier, :with, {__MODULE__, :build_struct, []})

    field :struct_a, :struct_a
    field :struct_b, :struct_b
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
        field :foo, non_null(:string)
      end

      middleware JetExt.Absinthe.OneOf.Middleware.InputModifier
      resolve &one_of_test_mutation/2
    end

    payload field(:one_of_test_struct_mutation) do
      input do
        field :struct, non_null(:one_of_test_struct_type)
      end

      output do
        field :struct, :string
      end

      middleware JetExt.Absinthe.OneOf.Middleware.InputModifier
      resolve &one_of_test_struct_mutation/2
    end
  end

  defp one_of_test_mutation(args, _resolution) do
    case Enum.to_list(args.foo) do
      [{_key, value}] -> {:ok, %{foo: value}}
      _otherwise -> {:error, "invalid arguments"}
    end
  end

  defp one_of_test_struct_mutation(args, _resolution) do
    {:ok, %{struct: inspect(args.struct)}}
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

  @spec build_struct(data :: map(), input_object) :: {map(), input_object}
        when input_object: Absinthe.Blueprint.Input.Object.t()
  def build_struct(data, input_object) do
    import JetExt.Absinthe.OneOf.Helpers

    {key, value} = unwrap_data(data)

    struct =
      case key do
        :struct_a -> struct(A, value)
        :struct_b -> struct(B, value)
      end

    {
      struct,
      unwrap_input_object(input_object)
    }
  end
end
