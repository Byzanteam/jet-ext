defmodule JetExt.Ecto.Schemaless.Query do
  @moduledoc false

  use TypedStruct

  require Ecto.Query

  alias JetExt.Ecto.Schemaless.Schema

  @type filter() :: nil | {:is_not, term()} | {:in, [term()]} | term()

  typedstruct do
    field :schema, Schema.t(), enforce: true
    field :query, Ecto.Query.t()
  end

  @spec from(t() | Schema.t()) :: t()
  def from(%__MODULE__{} = query) do
    query
  end

  def from(schema) do
    %__MODULE__{schema: schema}
  end

  @spec select(t(), fields :: [atom()]) :: t()
  def select(%__MODULE__{} = query, fields) do
    update_ecto_query(query, &select(&1, query.schema, fields))
  end

  @spec select(Ecto.Queryable.t(), Schema.t(), fields :: [atom()]) :: Ecto.Query.t()
  def select(queryable, %Schema{} = schema, fields) do
    selects = select_map(fields, schema.types)
    Ecto.Query.select(queryable, ^selects)
  end

  defp select_map(fields, types) do
    Map.new(fields, fn field ->
      type = Map.fetch!(types, field)

      {
        field,
        Ecto.Query.dynamic([q], type(field(q, ^field), ^type))
      }
    end)
  end

  @spec where(t(), filters :: keyword(filter())) :: t()
  def where(%__MODULE__{} = query, filters) do
    update_ecto_query(query, &apply_filters(&1, filters, query.schema.types, :and))
  end

  @spec or_where(t(), filters :: keyword(filter())) :: t()
  def or_where(%__MODULE__{} = query, filters) do
    update_ecto_query(query, &apply_filters(&1, filters, query.schema.types, :or))
  end

  defp apply_filters(query, filters, types, :and) do
    Enum.reduce(filters, query, fn {field, filter}, acc ->
      type = Map.fetch!(types, field)
      Ecto.Query.where(acc, ^filter_dynamic(field, type, filter))
    end)
  end

  defp apply_filters(query, filters, types, :or) do
    Enum.reduce(filters, query, fn {field, filter}, acc ->
      type = Map.fetch!(types, field)
      Ecto.Query.or_where(acc, ^filter_dynamic(field, type, filter))
    end)
  end

  defp filter_dynamic(field, _type, nil) do
    Ecto.Query.dynamic([q], is_nil(field(q, ^field)))
  end

  defp filter_dynamic(field, type, {:in, values}) do
    Ecto.Query.dynamic([q], field(q, ^field) in type(^values, ^{:array, type}))
  end

  defp filter_dynamic(field, _type, {:is_not, nil}) do
    Ecto.Query.dynamic([q], not is_nil(field(q, ^field)))
  end

  defp filter_dynamic(field, type, {:is_not, value}) do
    Ecto.Query.dynamic([q], not field(q, ^field) == type(^value, ^type))
  end

  defp filter_dynamic(field, type, value) do
    Ecto.Query.dynamic([q], field(q, ^field) == type(^value, ^type))
  end

  @spec update_ecto_query(t(), (Ecto.Query.t() -> Ecto.Query.t())) :: t()
  def update_ecto_query(%__MODULE__{query: ecto_query} = query, fun) when is_function(fun, 1) do
    %{query | query: fun.(ecto_query || build_query(query))}
  end

  @spec update_ecto_query(t(), (Ecto.Query.t(), Schema.t() -> Ecto.Query.t())) :: t()
  def update_ecto_query(%__MODULE__{query: ecto_query} = query, fun) when is_function(fun, 2) do
    %{query | query: fun.(ecto_query || build_query(query), query.schema)}
  end

  defp build_query(query) do
    source = query.schema.source
    ecto_query = Ecto.Query.from(source)

    case query.schema.prefix do
      nil ->
        ecto_query

      prefix ->
        Ecto.Query.put_query_prefix(ecto_query, prefix)
    end
  end

  defimpl Ecto.Queryable do
    # credo:disable-for-next-line Credo.Check.Readability.Specs
    def to_query(%{query: nil} = query) do
      query |> select_all_fields() |> Map.fetch!(:query)
    end

    # credo:disable-for-next-line Credo.Check.Readability.Specs
    def to_query(query) do
      if is_nil(query.query.select) do
        query |> select_all_fields() |> Map.fetch!(:query)
      else
        Map.fetch!(query, :query)
      end
    end

    defp select_all_fields(query) do
      fields = Map.keys(query.schema.types)
      @for.select(query, fields)
    end
  end

  if Code.ensure_loaded?(Absinthe.Relay) do
    defimpl JetExt.Absinthe.Relay.Connection.FieldType do
      # credo:disable-for-next-line Credo.Check.Readability.Specs
      def get_type(query, field) do
        case Map.fetch(query.schema.types, field) do
          {:ok, type} ->
            type

          :error ->
            raise "Field #{inspect(field)} not found in schema #{inspect(query.schema)}"
        end
      end
    end
  end
end
