defmodule JetExt.Absinthe.Relay.Connection.QueryTest do
  use ExUnit.Case, async: true

  alias JetExt.Absinthe.Relay.Connection.Config
  alias JetExt.Absinthe.Relay.Connection.Query

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field :age, :integer
      field :name, :string
    end
  end

  test "works" do
    config =
      Config.new(
        after: %{age: 20, name: "Alice"},
        direction: :forward,
        cursor_fields: [age: :asc, name: :asc]
      )

    assert expr(Query.paginate(User, config)) ===
             ~s{#Ecto.Query<from u0 in JetExt.Absinthe.Relay.Connection.QueryTest.User,} <>
               ~s{ where: u0.age > ^20} <>
               ~s{ or (u0.name > ^"Alice" and u0.age == ^20),} <>
               ~s{ order_by: [asc: u0.age, asc: u0.name],} <>
               ~s{ limit: ^51,} <> ~s{ select: [:age, :name, :id]>}
  end

  test "works with include_head_edge and include_tail_edge" do
    config =
      Config.new(
        after: %{age: 20},
        before: %{age: 60},
        direction: :forward,
        cursor_fields: [age: :asc],
        include_head_edge: true,
        include_tail_edge: true
      )

    assert expr(Query.paginate(User, config)) ===
             ~s{#Ecto.Query<from u0 in JetExt.Absinthe.Relay.Connection.QueryTest.User,} <>
               ~s{ where: u0.age == ^20} <>
               ~s{ or u0.age == ^60} <>
               ~s{ or (u0.age > ^20 and u0.age < ^60),} <>
               ~s{ order_by: [asc: u0.age],} <>
               ~s{ limit: ^51,} <> ~s{ select: [:age, :id, :name]>}
  end

  test "works with include_head_edge and include_tail_edge, nil values" do
    config =
      Config.new(
        after: %{age: 20, name: nil},
        before: %{age: 60, name: "Alice"},
        direction: :forward,
        cursor_fields: [age: :asc],
        include_head_edge: true,
        include_tail_edge: true
      )

    assert expr(Query.paginate(User, config)) ===
             ~s{#Ecto.Query<from u0 in JetExt.Absinthe.Relay.Connection.QueryTest.User, } <>
               ~s{where: (is_nil(u0.name) and u0.age == ^20)} <>
               ~s{ or (u0.name == ^"Alice" and u0.age == ^60)} <>
               ~s{ or\n  (u0.age > ^20 and u0.age < ^60),} <>
               ~s{ order_by: [asc: u0.age],} <>
               ~s{ limit: ^51,} <>
               ~s{ select: [:age, :id, :name]>}
  end

  defp expr(query) do
    query |> inspect() |> Inspect.Algebra.format(80) |> to_string()
  end
end
