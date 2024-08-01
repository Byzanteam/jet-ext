defmodule JetExt.Ecto.Schemaless.RepoTest do
  use JetExt.Case.Database, async: false

  alias JetExt.Ecto.Schemaless.Query
  alias JetExt.Ecto.Schemaless.Repo

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

  setup :setup_tables

  describe "insert_all/4" do
    @describetag [tables: [{@movie_name, @movie_columns}]]

    test "works" do
      schema = build_schema(@movie_name, @movie_columns)

      entries = [
        %{
          "title" => "Longlegs",
          "likes" => 1024,
          "released" => false,
          "release_date" => "2024-12-31",
          "tags" => ["Crime", "Horror", "Thriller"]
        },
        %{
          "title" => "Twisters",
          "likes" => 1024,
          "released" => false,
          "release_date" => "2024-12-31",
          "tags" => ["Action", "Adventure", "Thriller"]
        },
        %{
          "title" => "Find Me Falling",
          "likes" => 1024,
          "released" => false,
          "release_date" => "2024-12-31",
          "tags" => ["Comedy", "Music", "Romance"]
        }
      ]

      assert {:ok, {3, nil}} = Repo.insert_all(JetExt.Repo, schema, entries)

      assert [%{title: "Longlegs"}, %{title: "Twisters"}, %{title: "Find Me Falling"}] =
               JetExt.Repo.all(Query.from(schema))
    end
  end
end
