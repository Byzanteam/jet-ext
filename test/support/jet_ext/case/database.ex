defmodule JetExt.Case.Database do
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias JetExt.Ecto.Schemaless.Schema, as: SchemalessSchema

  @types %{
    {:array, :text} => {:array, :string},
    uuid: Ecto.UUID,
    text: :string,
    numeric: :decimal,
    boolean: :boolean,
    timestamp: :utc_datetime_usec,
    date: :date
  }

  @generators %{
    uuid: {Ecto.UUID, :generate, []},
    timestamp: {DateTime, :utc_now, []}
  }

  using do
    quote location: :keep do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import unquote(__MODULE__)
    end
  end

  setup ctx do
    JetExt.Case.Database.setup_sandbox(ctx)
  end

  @doc """
  Sets up the sandbox based on the test context.
  """
  @spec setup_sandbox(ctx :: map()) :: :ok
  def setup_sandbox(%{async: async}) do
    pid = Sandbox.start_owner!(JetExt.Repo, shared: not async)
    on_exit(fn -> Sandbox.stop_owner(pid) end)
  end

  @spec setup_tables(ctx :: map()) :: :ok
  def setup_tables(ctx) do
    ctx
    |> Map.get(:tables, [])
    |> Enum.each(fn {name, columns} ->
      table = Ecto.Migration.table(name)

      {:ok, _result} = JetExt.Repo.execute_ddl({:create, table, columns})

      on_exit({:drop_table, name}, fn ->
        {:ok, _result} = JetExt.Repo.execute_ddl({:drop_if_exists, table, :restrict})
      end)
    end)
  end

  @spec build_schema(table :: binary, columns :: [term()]) :: SchemalessSchema.t()
  def build_schema(table, columns) do
    types =
      Map.new(columns, fn {:add, name, type, _opts} ->
        {name, Map.fetch!(@types, type)}
      end)

    options = [
      source: table,
      primary_key: build_primary_key(columns),
      autogenerate: build_autogenerate(columns)
    ]

    SchemalessSchema.new(types, options)
  end

  defp build_primary_key(columns) do
    Enum.flat_map(columns, fn {:add, name, _type, opts} ->
      if Keyword.get(opts, :primary_key, false), do: [name], else: []
    end)
  end

  defp build_autogenerate(columns) do
    Enum.flat_map(columns, fn {:add, name, type, opts} ->
      if Keyword.get(opts, :auto_generate, false),
        do: [{[name], Map.fetch!(@generators, type)}],
        else: []
    end)
  end
end
