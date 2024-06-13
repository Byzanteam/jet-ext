defmodule JetExt.Ecto.Schemaless.Repo do
  @moduledoc false

  alias JetExt.Ecto.Schemaless.Query
  alias JetExt.Ecto.Schemaless.Schema

  @type row() :: map()

  @spec insert(Ecto.Repo.t(), Schema.t(), row() | changeset, options :: keyword()) ::
          {:ok, row()} | {:error, changeset | term()}
        when changeset: Ecto.Changeset.t(row())
  def insert(repo, schema, row, options \\ [])

  def insert(repo, schema, %Ecto.Changeset{} = changeset, options) do
    apply_action(:insert, repo, schema, changeset, options)
  end

  @spec update(Ecto.Repo.t(), Schema.t(), changeset, options :: keyword()) ::
          {:ok, row()} | {:error, changeset | term()}
        when changeset: Ecto.Changeset.t(row())
  def update(repo, schema, changeset, options \\ [])

  def update(repo, schema, changeset, options) do
    apply_action(:update, repo, schema, changeset, options)
  end

  defp apply_action(action, repo, schema, changeset, options) do
    with({:invalid, constraints} <- do_apply_action(action, repo, schema, changeset, options)) do
      {:error, constraints_to_errors(schema.constraints, changeset, constraints)}
    end
  end

  defp do_apply_action(action, repo, schema, changeset, options) do
    changeset = Schema.autogenerate_changes(schema, Map.put(changeset, :action, action))

    if changeset.valid? do
      options =
        case schema.prefix do
          nil -> options
          prefix -> [{:prefix, prefix} | options]
        end

      handle_action(action, repo, schema, changeset, options)
    else
      {:error, changeset}
    end
  rescue
    error ->
      case to_constraints(error) do
        [] ->
          reraise(error, __STACKTRACE__)

        constraints ->
          {:invalid, constraints}
      end
  end

  defp handle_action(:insert, repo, schema, changeset, options) do
    row = Ecto.Changeset.apply_action!(changeset, changeset.action)

    case repo.insert_all(schema.source, [build_insertion(schema, row)], options) do
      {1, _returning} -> {:ok, row}
      {_count, reason} -> {:error, reason}
    end
  end

  defp handle_action(:update, repo, schema, changeset, options) do
    import Ecto.Query, only: [exclude: 2]

    query = schema |> query_by_pk(changeset) |> exclude(:select)

    case repo.update_all(query, [set: build_changes(changeset)], options) do
      {1, _returning} -> {:ok, Ecto.Changeset.apply_changes(changeset)}
      {_count, reason} -> {:error, reason}
    end
  end

  defp build_insertion(schema, row) do
    schema
    |> Schema.dump(row)
    |> Stream.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp build_changes(changeset) do
    types = changeset.types

    Enum.map(changeset.changes, fn {field, value} ->
      {:ok, value} = types |> Map.fetch!(field) |> Ecto.Type.dump(value)
      {field, value}
    end)
  end

  @spec delete(Ecto.Repo.t(), Schema.t(), row(), options :: keyword()) ::
          {:ok, row()} | {:error, term()}
  def delete(repo, schema, row, options) do
    import Ecto.Query, only: [exclude: 2]

    query = schema |> query_by_pk(row) |> exclude(:select)

    options =
      case schema.prefix do
        nil -> options
        prefix -> [{:prefix, prefix} | options]
      end

    case repo.delete_all(query, options) do
      {1, nil} -> {:ok, row}
      {_count, reason} -> {:error, reason}
    end
  end

  defp query_by_pk(schema, row) do
    schema |> Query.from() |> Query.where(Schema.primary_key(schema, row))
  end

  defp constraints_to_errors(constraint_definitions, changeset, constraints) do
    constraint_errors =
      Enum.map(constraints, fn {type, constraint} ->
        case find_constraint(constraint_definitions, {type, constraint}) do
          %{field: field, error_message: error_message, error_type: error_type} ->
            {field, {error_message, [constraint: error_type, constraint_name: constraint]}}

          nil ->
            raise Ecto.ConstraintError,
              action: changeset.action,
              type: type,
              constraint: constraint,
              changeset: changeset
        end
      end)

    %{changeset | errors: constraint_errors ++ changeset.errors, valid?: false}
  end

  defp find_constraint(constraint_definitions, {type, constraint}) do
    Enum.find(constraint_definitions, fn c ->
      case {c.type, c.constraint, c.match} do
        {^type, ^constraint, :exact} -> true
        {^type, cc, :suffix} -> String.ends_with?(constraint, cc)
        {^type, cc, :prefix} -> String.starts_with?(constraint, cc)
        {^type, %Regex{} = r, _match} -> Regex.match?(r, constraint)
        _otherwise -> false
      end
    end)
  end

  defp to_constraints(%Postgrex.Error{
         postgres: %{code: :unique_violation, constraint: constraint}
       }),
       do: [unique: constraint]

  defp to_constraints(%Postgrex.Error{
         postgres: %{code: :foreign_key_violation, constraint: constraint}
       }),
       do: [foreign_key: constraint]

  defp to_constraints(_error), do: []
end
