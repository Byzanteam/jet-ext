defmodule JetExt.Ecto.Schemaless.Multi do
  @moduledoc false

  alias JetExt.Ecto.Schemaless.Repo
  alias JetExt.Ecto.Schemaless.Schema

  @type row() :: map()

  @spec insert(
          Ecto.Multi.t(),
          Ecto.Multi.name(),
          (changes :: map() -> {Schema.t(), Ecto.Changeset.t(row())}),
          options :: keyword()
        ) ::
          Ecto.Multi.t()
  def insert(multi, name, fun, options) do
    Ecto.Multi.run(multi, name, fn repo, changes ->
      {schema, changeset} = fun.(changes)

      Repo.insert(repo, schema, changeset, options)
    end)
  end

  @spec update(
          Ecto.Multi.t(),
          Ecto.Multi.name(),
          (changes :: map() -> {Schema.t(), Ecto.Changeset.t(row())}),
          options :: keyword()
        ) :: Ecto.Multi.t()
  def update(multi, name, fun, options) do
    Ecto.Multi.run(multi, name, fn repo, changes ->
      {schema, changeset} = fun.(changes)

      Repo.update(repo, schema, changeset, options)
    end)
  end

  @spec insert_all(
          Ecto.Multi.t(),
          Ecto.Multi.name(),
          (changes :: map() ->
             {Schema.t(), [Ecto.Changeset.t(row())]}
             | {Schema.t(), [Ecto.Changeset.t(row())], options :: keyword()}),
          options :: keyword()
        ) :: Ecto.Multi.t()
  def insert_all(multi, name, fun, options) do
    Ecto.Multi.run(multi, name, fn repo, changes ->
      do_insert_all(fun.(changes), repo, options)
    end)
  end

  defp do_insert_all({schema, rows}, repo, options) do
    do_insert_all({schema, rows, []}, repo, options)
  end

  defp do_insert_all({schema, rows, options_override}, repo, options) do
    source = schema.source

    options =
      case schema.prefix do
        nil -> options
        prefix -> [{:prefix, prefix} | options]
      end

    options = Keyword.merge(options, options_override)

    with({:ok, insertions} <- build_insertions(schema, rows)) do
      {:ok, repo.insert_all(source, insertions, options)}
    end
  end

  defp build_insertions(schema, rows) do
    result =
      Enum.reduce_while(rows, {:ok, []}, fn row, {:ok, acc} ->
        if row.valid? do
          {:cont, {:ok, [build_insertion(schema, row) | acc]}}
        else
          {:halt, {:error, row}}
        end
      end)

    with({:ok, rows} <- result) do
      {:ok, Enum.reverse(rows)}
    end
  end

  defp build_insertion(schema, row) do
    row = Schema.autogenerate_changes(schema, Map.put(row, :action, :insert))

    schema
    |> Schema.dump(Ecto.Changeset.apply_changes(row))
    |> Stream.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
