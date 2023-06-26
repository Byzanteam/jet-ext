defmodule JetExt.Absinthe.Relay.Connection do
  @moduledoc false

  require Logger

  alias JetExt.Absinthe.Relay.Connection.Config
  alias JetExt.Absinthe.Relay.Connection.Cursor
  alias JetExt.Absinthe.Relay.Connection.Query

  @doc """
  Build a cursor_based connection from an Ecto Query
  """
  @spec from_query(
          Ecto.Queryable.t(),
          (Ecto.Queryable.t() -> [term()]),
          map(),
          Keyword.t()
        ) :: {:ok, map()} | {:error, term()}
  def from_query(query, repo_fun, args, opts \\ []) do
    with {:ok, config} <- build_config(args, opts) do
      config = %{
        config
        | cursor_fields: Keyword.fetch!(opts, :cursor_fields),
          include_head_edge: Keyword.get(opts, :include_head_edge) || false,
          include_tail_edge: Keyword.get(opts, :include_tail_edge) || false
      }

      {
        edges,
        first,
        last,
        has_previous_page,
        has_next_page
      } =
        query
        |> Query.paginate(config)
        |> repo_fun.()
        |> build_cursors(config)

      page_info = %{
        start_cursor: first,
        end_cursor: last,
        has_previous_page:
          has_page?(:previous, {query, repo_fun}, first, config, has_previous_page),
        has_next_page: has_page?(:next, {query, repo_fun}, last, config, has_next_page)
      }

      {:ok, %{edges: edges, page_info: page_info}}
    end
  end

  defp build_config(%{first: first} = args, opts) do
    do_build_config(:forward, first, args, opts)
  end

  defp build_config(%{last: last} = args, opts) do
    do_build_config(:backward, last, args, opts)
  end

  defp build_config(_args, _opts), do: {:error, "You must either supply `:first` or `:last`"}

  defp do_build_config(direction, limit, args, opts) do
    with(
      {:ok, before_cursor} <- Cursor.decode(args[:before]),
      {:ok, after_cursor} <- Cursor.decode(args[:after])
    ) do
      {:ok,
       Config.new(
         direction: direction,
         before: before_cursor,
         after: after_cursor,
         limit: limit,
         maximum_limit: opts[:maximum_limit]
       )}
    end
  end

  # {edges, first, last, has_previous_page, has_next_page}
  defp build_cursors([], _config), do: {[], nil, nil, false, false}

  defp build_cursors([first | _] = sorted_entries, %Config{} = config) do
    first = build_cursor(first, config)
    do_build_cursors(sorted_entries, 0, {[], first, nil}, config)
  end

  # entries.count > limit
  defp do_build_cursors(
         [_ | _],
         count,
         {edges, first, last},
         %Config{direction: :forward, limit: count} = config
       ) do
    {Enum.reverse(edges), first, last, not is_nil(config.after), true}
  end

  defp do_build_cursors(
         [_ | _],
         count,
         {edges, first, last},
         %Config{direction: :backward, limit: count} = config
       ) do
    {edges, last, first, true, not is_nil(config.before)}
  end

  # entries.count = limit
  defp do_build_cursors(
         [],
         count,
         {edges, first, last},
         %Config{direction: :forward, limit: count} = config
       ) do
    {Enum.reverse(edges), first, last, not is_nil(config.after), not is_nil(config.before)}
  end

  defp do_build_cursors(
         [],
         count,
         {edges, first, last},
         %Config{direction: :backward, limit: count} = config
       ) do
    {edges, last, first, not is_nil(config.after), not is_nil(config.before)}
  end

  # entries.count < limit
  defp do_build_cursors([], _count, {edges, first, last}, %Config{direction: :forward} = config) do
    {Enum.reverse(edges), first, last, not is_nil(config.after), not is_nil(config.before)}
  end

  defp do_build_cursors([], _count, {edges, first, last}, %Config{direction: :backward} = config) do
    {edges, last, first, not is_nil(config.after), not is_nil(config.before)}
  end

  defp do_build_cursors([item | rest], count, {edges, first, _last}, %Config{} = config) do
    cursor = build_cursor(item, config)
    edge = build_edge(item, cursor)

    do_build_cursors(rest, count + 1, {[edge | edges], first, cursor}, config)
  end

  defp build_cursor({item, _args}, config) do
    build_cursor(item, config)
  end

  defp build_cursor(item, config) do
    Cursor.encode_record(item, config)
  end

  defp build_edge({item, args}, cursor) do
    args
    |> Enum.flat_map(fn
      {key, _} when key in [:cursor, :node] ->
        Logger.warn("Ignoring additional #{key} provided on edge (overriding is not allowed)")
        []

      {key, val} ->
        [{key, val}]
    end)
    |> Enum.into(build_edge(item, cursor))
  end

  defp build_edge(item, cursor) do
    %{
      node: item,
      cursor: cursor
    }
  end

  defp has_page?(
         :previous,
         {query, repo_fun},
         start_cursor,
         %{include_head_edge: true, after: after_cursor} = config,
         _default
       )
       when not is_nil(after_cursor) do
    # credo:disable-for-previous-line Credo.Check.Refactor.NegatedIsNil
    {:ok, cursor} =
      if is_nil(start_cursor) do
        {:ok, after_cursor}
      else
        Cursor.decode(start_cursor)
      end

    edges_exists?(query, repo_fun, %{
      Config.disable_edge_including(config)
      | before: cursor,
        after: nil
    })
  end

  defp has_page?(
         :next,
         {query, repo_fun},
         end_cursor,
         %{include_tail_edge: true, before: before_cursor} = config,
         _default
       )
       when not is_nil(before_cursor) do
    # credo:disable-for-previous-line Credo.Check.Refactor.NegatedIsNil
    {:ok, cursor} =
      if is_nil(end_cursor) do
        {:ok, before_cursor}
      else
        Cursor.decode(end_cursor)
      end

    edges_exists?(query, repo_fun, %{
      Config.disable_edge_including(config)
      | before: nil,
        after: cursor
    })
  end

  defp has_page?(_side, {_query, _repo_fun}, _side_edge, _config, default), do: default

  defp edges_exists?(query, repo_fun, config) do
    import Ecto.Query

    query
    |> Query.paginate(config)
    |> exclude(:select)
    |> exclude(:preload)
    |> exclude(:order_by)
    |> exclude(:distinct)
    |> select(1)
    |> limit(1)
    |> repo_fun.()
    |> case do
      [1] -> true
      [] -> false
    end
  end
end
