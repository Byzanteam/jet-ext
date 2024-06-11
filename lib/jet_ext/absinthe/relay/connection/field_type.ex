if Code.ensure_loaded?(Absinthe.Relay) do
  defprotocol JetExt.Absinthe.Relay.Connection.FieldType do
    @doc "Get the field type for a field of a queryable."
    @spec get_type(t(), atom()) :: Ecto.Type.t()
    def get_type(queryable, field)
  end

  defimpl JetExt.Absinthe.Relay.Connection.FieldType, for: Ecto.Query do
    def get_type(%{from: %Ecto.Query.FromExpr{source: {_source, nil}}} = query, _field) do
      raise "Schemaless queries are not supported, query: #{inspect(query)}"
    end

    def get_type(%{from: %Ecto.Query.FromExpr{source: {_source, schema}}} = query, field) do
      type = schema.__schema__(:type, field)

      if is_nil(type) do
        raise "Field #{inspect(field)} not found in schema #{inspect(schema)}, query: #{inspect(query)}"
      else
        type
      end
    end
  end

  defimpl JetExt.Absinthe.Relay.Connection.FieldType, for: Atom do
    def get_type(schema, field) do
      if function_exported?(schema, :__schema__, 2) do
        type = schema.__schema__(:type, field)

        if is_nil(type) do
          raise "Field #{inspect(field)} not found in schema #{inspect(schema)}"
        else
          type
        end
      else
        raise "The schema #{inspect(schema)} is not an Ecto schema."
      end
    end
  end
end
