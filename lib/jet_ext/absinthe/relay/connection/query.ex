defmodule JetExt.Absinthe.Relay.Connection.Query do
  @moduledoc false

  import Ecto.Query

  alias JetExt.Absinthe.Relay.Connection.Config

  @spec paginate(Ecto.Queryable.t(), Config.t()) :: Ecto.Queryable.t()
  def paginate(queryable, %Config{} = config) do
    queryable
    |> select_merge([q], ^Keyword.keys(config.cursor_fields))
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
    {condition, side_edge_condition} = filter_values(cursor_fields, after_values, :after, config)
    wheres = or_join_dynamics([side_edge_condition, condition])

    from(query, where: ^wheres)
  end

  defp maybe_where(
         query,
         %Config{
           after: nil,
           before: before_values,
           cursor_fields: cursor_fields
         } = config
       ) do
    {condition, side_edge_condition} =
      filter_values(cursor_fields, before_values, :before, config)

    wheres = or_join_dynamics([side_edge_condition, condition])

    from(query, where: ^wheres)
  end

  defp maybe_where(
         query,
         %Config{
           after: after_values,
           before: before_values,
           cursor_fields: cursor_fields
         } = config
       ) do
    {after_condition, head_edge_condition} =
      filter_values(cursor_fields, after_values, :after, config)

    {before_condition, tail_edge_condition} =
      filter_values(cursor_fields, before_values, :before, config)

    conditions = and_join_dynamics([after_condition, before_condition])

    wheres = or_join_dynamics([head_edge_condition, tail_edge_condition, conditions])

    from(query, where: ^wheres)
  end

  defp get_operator("asc" <> _tail, :before), do: :lt
  defp get_operator("desc" <> _tail, :before), do: :gt
  defp get_operator("asc" <> _tail, :after), do: :gt
  defp get_operator("desc" <> _tail, :after), do: :lt

  defp get_operator(direction, _cursor),
    do:
      raise("""
      Invalid sorting value :#{direction},
      please use :asc, :asc_nulls_last, :asc_nulls_first, :desc, :desc_nulls_last, :desc_nulls_first
      """)

  defp get_operator_for_field(cursor_fields, key, direction) do
    cursor_fields
    |> Enum.find_value(fn {field_key, order} ->
      if field_key === key, do: Atom.to_string(order)
    end)
    |> get_operator(direction)
  end

  defp filter_values(cursor_fields, values, cursor_direction, config) do
    # keep the order with order_by in `order_query/2`
    sorts =
      cursor_fields
      |> Enum.reduce([], fn {field, _direction}, acc ->
        case Map.fetch(values, field) do
          :error -> acc
          {:ok, nil} -> acc
          {:ok, value} -> [{field, value} | acc]
        end
      end)
      |> Enum.reverse()

    conditions =
      sorts
      |> Enum.with_index()
      |> Enum.map(fn {{column, value}, i} ->
        field_dynamic =
          case get_operator_for_field(cursor_fields, column, cursor_direction) do
            :lt -> dynamic([q], field(q, ^column) < ^value)
            :gt -> dynamic([q], field(q, ^column) > ^value)
          end

        prev_dynamics =
          sorts
          |> Enum.take(i)
          |> Enum.map(fn {prev_column, prev_value} ->
            dynamic([q], field(q, ^prev_column) == ^prev_value)
          end)

        and_join_dynamics([field_dynamic | prev_dynamics])
      end)
      |> or_join_dynamics()

    # note: side edges should take `nil` values into account
    {conditions, build_side_edge_condition(cursor_direction, config, values)}
  end

  defp build_side_edge_condition(:after, %{include_head_edge: true}, values),
    do: build_side_edge_condition(values)

  defp build_side_edge_condition(:before, %{include_tail_edge: true}, values),
    do: build_side_edge_condition(values)

  defp build_side_edge_condition(_cursor_direction, _config, _values), do: false

  defp build_side_edge_condition(values) when is_map(values) do
    values
    |> Enum.map(fn
      {column, nil} -> dynamic([q], is_nil(field(q, ^column)))
      {column, value} -> dynamic([q], field(q, ^column) == ^value)
    end)
    |> and_join_dynamics()
  end

  defp and_join_dynamics(conditions, acc \\ true)
  defp and_join_dynamics([], acc), do: acc
  defp and_join_dynamics([true | rest], acc), do: and_join_dynamics(rest, acc)
  defp and_join_dynamics([first | rest], true), do: and_join_dynamics(rest, first)

  defp and_join_dynamics([first | rest], acc),
    do: and_join_dynamics(rest, dynamic([q], ^acc and ^first))

  defp or_join_dynamics(conditions, acc \\ false)
  defp or_join_dynamics([], acc), do: acc
  defp or_join_dynamics([false | rest], acc), do: or_join_dynamics(rest, acc)
  defp or_join_dynamics([first | rest], false), do: or_join_dynamics(rest, first)

  defp or_join_dynamics([first | rest], acc),
    do: or_join_dynamics(rest, dynamic([q], ^acc or ^first))

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
