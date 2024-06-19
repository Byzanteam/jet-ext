defprotocol JetExt.Absinthe.Relay.Connection.Cursor.Extractor do
  @moduledoc false

  @spec extract(t(), cursor_fields :: [atom()]) :: map()
  def extract(data, cursor_fields)
end

defimpl JetExt.Absinthe.Relay.Connection.Cursor.Extractor, for: Map do
  def extract(data, cursor_fields) do
    Map.take(data, cursor_fields)
  end
end

defimpl JetExt.Absinthe.Relay.Connection.Cursor.Extractor, for: Any do
  defmacro __deriving__(module, _struct, _opts) do
    quote do
      defimpl JetExt.Absinthe.Relay.Connection.Cursor.Extractor, for: unquote(module) do
        def extract(data, cursor_fields) do
          Map.take(data, cursor_fields)
        end
      end
    end
  end

  def extract(_data, _cursor_fields) do
    raise "Not implemented"
  end
end
