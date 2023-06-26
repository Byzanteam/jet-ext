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

    assert %Ecto.Query{
             from: %{source: {"users", User}},
             limit: %{params: [{51, :integer}]},
             order_bys: [
               %{
                 expr: [
                   asc: {{:., [], [{:&, [], [0]}, :age]}, [], []},
                   asc: {{:., [], [{:&, [], [0]}, :name]}, [], []}
                 ]
               }
             ],
             wheres: [
               %{
                 expr: {
                   :or,
                   [],
                   [
                     {:>, [], [{{:., [], [{:&, [], [0]}, :age]}, [], []}, {:^, [], [0]}]},
                     {:and, [],
                      [
                        {:>, [], [{{:., [], [{:&, [], [0]}, :name]}, [], []}, {:^, [], [1]}]},
                        {:==, [], [{{:., [], [{:&, [], [0]}, :age]}, [], []}, {:^, [], [2]}]}
                      ]}
                   ]
                 },
                 params: [{20, {0, :age}}, {"Alice", {0, :name}}, {20, {0, :age}}]
               }
             ]
           } = Query.paginate(User, config)
  end
end
