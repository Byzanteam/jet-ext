if Code.ensure_loaded?(Absinthe) and Code.ensure_loaded?(Absinthe.Relay) do
  defmodule JetExt.Absinthe.NotationBuilder do
    @moduledoc false

    defmacro __using__(opts) do
      primary_key = Keyword.fetch!(opts, :primary_key)
      pk_name = Keyword.fetch!(primary_key, :name)
      pk_source_name = Keyword.fetch!(primary_key, :source_name)
      pk_type = Keyword.fetch!(primary_key, :type)

      quote location: :keep,
            unquote: false,
            bind_quoted: [pk_name: pk_name, pk_source_name: pk_source_name, pk_type: pk_type] do
        defmacro __using__(_opts) do
          quote location: :keep do
            use Absinthe.Schema.Notation
            use JetExt.Absinthe.Relay.Schema.Notation, :modern

            import unquote(__MODULE__)
          end
        end

        defmacro node_object(identifier, attrs, do: block) do
          {node_type, attrs} = Keyword.pop!(attrs, :node_type)
          {pk_name, attrs} = Keyword.pop(attrs, :name, unquote(pk_name))
          {pk_source_name, attrs} = Keyword.pop(attrs, :source_name, unquote(pk_source_name))
          {pk_type, attrs} = Keyword.pop(attrs, :type, unquote(pk_type))

          block = [
            quote do
              meta :node_type, unquote(node_type)
            end,
            quote do
              field unquote(pk_name), non_null(unquote(pk_type)),
                resolve: fn parent, _args, _res ->
                  {:ok, Map.fetch!(parent, unquote(pk_source_name))}
                end
            end,
            block
          ]

          quote do
            node(object(unquote(identifier), unquote(attrs)), do: unquote(block))
          end
        end

        defmacro relay_connection(attrs) do
          define_relay_connection(attrs, [])
        end

        defp define_relay_connection(attrs, block) do
          node_type = Keyword.fetch!(attrs, :node_type)

          quote do
            connection unquote(attrs) do
              field :nodes, list_of(unquote(node_type)) do
                resolve fn _args, %{source: conn} ->
                  {:ok, Enum.map(conn.edges, & &1.node)}
                end
              end

              unquote(block)
            end
          end
        end

        if Code.ensure_loaded?(Ecto) do
          defmacro define_enum(object, schema, field) do
            schema = Macro.expand(schema, __CALLER__)
            values = Ecto.Enum.values(schema, field)

            quote location: :keep do
              enum(unquote(object), values: unquote(values))
            end
          end
        end
      end
    end
  end
end
