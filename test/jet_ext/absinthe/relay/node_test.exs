defmodule JetExt.Absinthe.Relay.NodeTest do
  use ExUnit.Case, async: true

  defmodule Foo do
    defstruct [:id, :name]
  end

  defmodule CustomIDTranslator do
    @behaviour Absinthe.Relay.Node.IDTranslator

    @impl Absinthe.Relay.Node.IDTranslator
    def to_global_id(type_name, source_id, _schema) do
      {:ok, "#{type_name}:#{source_id}"}
    end

    @impl Absinthe.Relay.Node.IDTranslator
    def from_global_id(global_id, _schema) do
      case String.split(global_id, ":", parts: 2) do
        [type_name, source_id] ->
          {:ok, type_name, source_id}

        _otherwise ->
          {:error, "Could not extract value from ID `#{inspect(global_id)}`"}
      end
    end
  end

  defmodule Schema do
    use Absinthe.Schema

    use JetExt.Absinthe.Relay.Schema,
      flavor: :modern,
      global_id_translator: CustomIDTranslator

    @foos %{
      "1" => %Foo{id: "1", name: "Bar 1"},
      "2" => %Foo{id: "2", name: "Bar 2"}
    }

    node interface do
      resolve_type fn
        %Foo{}, _execution ->
          :foo
      end
    end

    node object(:foo) do
      field :id, :string
      field :name, :string
    end

    query do
      node field do
        resolve fn
          %{id: id, type: :foo}, _info ->
            {:ok, Map.get(@foos, id)}
        end
      end
    end
  end

  describe "node resolution" do
    test "works" do
      query = """
      query ($nodeId: ID!) {
        node(nodeId: $nodeId) {
          ... on Foo {
            id
            name
            nodeId
          }
        }
      }
      """

      result = Absinthe.run(query, Schema, variables: %{"nodeId" => "Foo:1"})

      assert {:ok, %{data: %{"node" => %{"id" => "1", "name" => "Bar 1", "nodeId" => "Foo:1"}}}} =
               result
    end
  end
end
