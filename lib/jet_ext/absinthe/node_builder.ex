if Code.ensure_loaded?(Absinthe) and Code.ensure_loaded?(Absinthe.Relay) do
  defmodule JetExt.Absinthe.NodeBuilder do
    @moduledoc false

    defmacro __using__(opts) do
      fetch_resource = Keyword.fetch!(opts, :fetch_resource)

      quote location: :keep do
        use Absinthe.Schema.Notation
        use JetExt.Absinthe.Relay.Schema.Notation, :modern

        node interface [] do
          resolve_type(&resolve_type/2)
        end

        object :node_query do
          node field [] do
            resolve(&resolve_node/2)
          end
        end

        defp resolve_type(object, %{schema: schema}) when is_struct(object) do
          schema
          |> Absinthe.Schema.types()
          |> Enum.find_value(fn type ->
            if is_struct(object, Absinthe.Type.meta(type, :node_type)) do
              type.identifier
            end
          end)
        end

        defp resolve_node(args, %{schema: schema}) do
          %{type: type, id: id} = args

          with {:ok, module} <- resolve_resource(schema, type) do
            unquote(fetch_resource).(module, id)
          end
        end

        defp resolve_resource(schema, type) do
          schema
          |> Absinthe.Schema.lookup_type(type)
          |> Absinthe.Type.meta(:node_type)
          |> case do
            nil -> {:error, :node_type}
            module -> {:ok, module}
          end
        end
      end
    end
  end
end
