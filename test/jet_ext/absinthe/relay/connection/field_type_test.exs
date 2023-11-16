defmodule JetExt.Absinthe.Relay.Connection.FieldTypeTest do
  use ExUnit.Case, async: true

  alias JetExt.Absinthe.Relay.Connection.FieldType

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field :age, :integer
      field :name, :string
      field :nonprimitive, Ecto.UUID
    end
  end

  test "get_type for a schema" do
    assert FieldType.get_type(User, :age) === :integer
    assert FieldType.get_type(User, :name) === :string
    assert FieldType.get_type(User, :nonprimitive) === Ecto.UUID

    assert_raise RuntimeError, ~r/Field :foo not found/, fn ->
      FieldType.get_type(User, :foo)
    end

    assert_raise RuntimeError, ~r/is not an Ecto schema/, fn ->
      FieldType.get_type(Post, :bar)
    end
  end

  test "get_type for an Ecto.Query" do
    import Ecto.Query

    query =
      User
      |> from(prefix: "pubilc")
      |> where(age: 1)
      |> join(:left, [u], p in "posts", on: u.id == p.user_id)
      |> select([u, p], %{id: u.id, post_counts: count(p.id)})

    assert FieldType.get_type(query, :age) === :integer
    assert FieldType.get_type(query, :name) === :string
    assert FieldType.get_type(query, :nonprimitive) === Ecto.UUID

    assert_raise RuntimeError, ~r/Field :foo not found/, fn ->
      FieldType.get_type(query, :foo)
    end

    assert_raise RuntimeError, ~r/Schemaless queries are not supported/, fn ->
      query = from(p in "posts", select: p)

      FieldType.get_type(query, :id)
    end
  end
end
