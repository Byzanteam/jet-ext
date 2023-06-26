defmodule JetExt.Absinthe.Relay.Connection.Query do
  @moduledoc false

  import Ecto.Query

  alias JetExt.Absinthe.Relay.Connection.Config

  @spec paginate(Ecto.Queryable.t(), Config.t()) :: Ecto.Queryable.t()
  def paginate(queryable, %Config{} = config) do
    queryable
    |> select_merge([q], map(q, ^Keyword.keys(config.cursor_fields)))
    |> order_query(config)
    |> maybe_where(config)
    |> limit(^query_limit(config))
  end

  defp maybe_where(query, %Config{
         after: nil,
         before: nil
       }) do
    query
  end

  defp maybe_where(
         query,
         %Config{
           after: after_values,
           before: nil,
           cursor_fields: cursor_fields
         } = config
       ) do
    condition = filter_values(cursor_fields, after_values, :after, config)

    from(query, where: ^condition)
  end

  defp maybe_where(
         query,
         %Config{
           after: nil,
           before: before_values,
           cursor_fields: cursor_fields
         } = config
       ) do
    condition = filter_values(cursor_fields, before_values, :before, config)

    from(query, where: ^condition)
  end

  defp maybe_where(
         query,
         %Config{
           after: after_values,
           before: before_values,
           cursor_fields: cursor_fields
         } = config
       ) do
    after_condition = filter_values(cursor_fields, after_values, :after, config)
    before_condition = filter_values(cursor_fields, before_values, :before, config)

    conditions = and_join_dynamics([after_condition, before_condition])

    from(query, where: ^conditions)
  end

  defp get_operator(:asc, :before), do: :lt
  defp get_operator(:desc, :before), do: :gt
  defp get_operator(:asc, :after), do: :gt
  defp get_operator(:desc, :after), do: :lt

  defp get_operator(direction, _cursor),
    do: raise("Invalid sorting value :#{direction}, please use either :asc or :desc")

  defp get_operator_for_field(cursor_fields, key, direction) do
    {_, order} =
      Enum.find(cursor_fields, fn {field_key, _order} ->
        field_key == key
      end)

    get_operator(order, direction)
  end

  defp filter_values(cursor_fields, values, cursor_direction, config) do
    # keep the order with order_by in `order_query/2`
    sorts =
      cursor_fields
      |> Enum.reduce([], fn {field, _direction}, acc ->
        case Map.fetch(values, field) do
          # credo:disable-for-next-line Credo.Check.Refactor.NegatedIsNil
          {:ok, value} when not is_nil(value) -> [{field, value} | acc]
          _otherwise -> acc
        end
      end)
      |> Enum.reverse()

    sorts
    |> Enum.with_index()
    |> Enum.map(fn {{column, value}, i} ->
      field_dynamic =
        case get_operator_for_field(cursor_fields, column, cursor_direction) do
          :lt ->
            dynamic([q], field(q, ^column) < ^value)

          :gt ->
            dynamic([q], field(q, ^column) > ^value)
        end

      prev_dynamics =
        sorts
        |> Enum.take(i)
        |> Enum.map(fn {prev_column, prev_value} ->
          dynamic([q], field(q, ^prev_column) == ^prev_value)
        end)

      and_join_dynamics([field_dynamic | prev_dynamics])
    end)
    |> add_side_edge_condition(cursor_direction, config, sorts)
    |> or_join_dynamics()
  end

  defp add_side_edge_condition(conditions, :after, %{include_head_edge: true}, values),
    do: build_side_edge_condition(conditions, values)

  defp add_side_edge_condition(conditions, :before, %{include_tail_edge: true}, values),
    do: build_side_edge_condition(conditions, values)

  defp add_side_edge_condition(conditions, _cursor_direction, _config, _values), do: conditions

  defp build_side_edge_condition(conditions, values)
       when is_list(conditions) and is_list(values) do
    condition =
      values
      |> Enum.map(fn {column, value} ->
        dynamic([q], field(q, ^column) == ^value)
      end)
      |> and_join_dynamics()

    [condition | conditions]
  end

  defp and_join_dynamics([]), do: true
  defp and_join_dynamics([condition]), do: condition

  defp and_join_dynamics([first | rest]) do
    Enum.reduce(rest, first, fn condition, acc ->
      dynamic([q], ^acc and ^condition)
    end)
  end

  defp or_join_dynamics([]), do: false
  defp or_join_dynamics([condition]), do: condition

  defp or_join_dynamics([first | rest]) do
    Enum.reduce(rest, first, fn condition, acc ->
      dynamic([q], ^acc or ^condition)
    end)
  end

  # In order to return the correct pagination cursors, we need to fetch one more
  # record than we actually want to return.
  defp query_limit(%Config{limit: limit}) do
    limit + 1
  end

  defp order_query(query, %Config{direction: :forward} = config) do
    do_order_query(query, config)
  end

  defp order_query(query, %Config{direction: :backward} = config) do
    query |> do_order_query(config) |> reverse_order()
  end

  defp do_order_query(query, %Config{cursor_fields: cursor_fields}) do
    bindings =
      for {field, direction} <- cursor_fields do
        {direction, field}
      end

    query
    |> exclude(:order_by)
    |> order_by(^bindings)
  end
end
