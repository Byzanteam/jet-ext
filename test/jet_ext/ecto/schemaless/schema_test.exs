defmodule JetExt.Ecto.Schemaless.SchemaTest do
  use JetExt.Case.Database, async: false

  alias JetExt.Ecto.Schemaless.Schema

  @movie_name "movies"

  @movie_columns [
    {:add, :id, :uuid, primary_key: true, auto_generate: true},
    {:add, :title, :text, null: false},
    {:add, :likes, :numeric, null: false},
    {:add, :released, :boolean, null: false},
    {:add, :release_date, :date, null: false},
    {:add, :created_at, :timestamp, null: false, auto_generate: true},
    {:add, :tags, {:array, :text}, null: false}
  ]

  describe "dump!/2" do
    setup :build_schema

    test "works", ctx do
      %{schema: schema} = ctx

      row = %{
        title: "Longlegs",
        likes: 1024,
        released: false,
        release_date: ~D[2024-12-31],
        created_at: ~U[2024-08-01 08:06:29.240326Z],
        tags: ["Crime", "Horror", "Thriller"]
      }

      assert %{
               title: "Longlegs",
               likes: %Decimal{coef: 1024},
               released: false,
               release_date: ~D[2024-12-31],
               created_at: ~U[2024-08-01 08:06:29.240326Z],
               tags: ["Crime", "Horror", "Thriller"]
             } = Schema.dump!(schema, row)
    end

    test "dumps only explicit keys", ctx do
      %{schema: schema} = ctx

      assert values = Schema.dump!(schema, %{title: "Longlegs"})
      assert [:title] = Map.keys(values)
    end

    test "keeps explicit nil", ctx do
      %{schema: schema} = ctx

      assert %{title: nil} = values = Schema.dump!(schema, %{title: nil})
      assert [:title] = Map.keys(values)
    end
  end

  defp build_schema(_ctx) do
    [schema: build_schema(@movie_name, @movie_columns)]
  end
end
