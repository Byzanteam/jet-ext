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

    assert %Ecto.Query{
             from: %{source: {"users", User}},
             limit: %{params: [{51, :integer}]},
             order_bys: [
               %{
                 expr: [
                   asc: {{:., [], [{:&, [], [0]}, :age]}, [], []}
                 ]
               }
             ],
             wheres: [
               %{
                 expr: {
                   :or,
                   [],
                   [
                     {
                       :or,
                       [],
                       [
                         {:==, [], [{{:., [], [{:&, [], [0]}, :age]}, [], []}, {:^, [], [0]}]},
                         {:==, [], [{{:., [], [{:&, [], [0]}, :age]}, [], []}, {:^, [], [1]}]}
                       ]
                     },
                     {
                       :and,
                       [],
                       [
                         {:>, [], [{{:., [], [{:&, [], [0]}, :age]}, [], []}, {:^, [], [2]}]},
                         {:<, [], [{{:., [], [{:&, [], [0]}, :age]}, [], []}, {:^, [], [3]}]}
                       ]
                     }
                   ]
                 },
                 params: [{20, {0, :age}}, {60, {0, :age}}, {20, {0, :age}}, {60, {0, :age}}]
               }
             ]
           } = Query.paginate(User, config)
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

    assert %Ecto.Query{
             from: %{source: {"users", User}},
             limit: %{params: [{51, :integer}]},
             order_bys: [
               %{
                 expr: [
                   asc: {{:., [], [{:&, [], [0]}, :age]}, [], []}
                 ]
               }
             ],
             wheres: [
               %{
                 expr: {
                   :or,
                   [],
                   [
                     # side edges
                     {
                       :or,
                       [],
                       [
                         # head
                         {
                           :and,
                           [],
                           [
                             {
                               :==,
                               [],
                               [{{:., [], [{:&, [], [0]}, :age]}, [], []}, {:^, [], [0]}]
                             },
                             {:is_nil, [], [{{:., [], [{:&, [], [0]}, :name]}, [], []}]}
                           ]
                         },

                         # tail
                         {
                           :and,
                           [],
                           [
                             {
                               :==,
                               [],
                               [{{:., [], [{:&, [], [0]}, :age]}, [], []}, {:^, [], [1]}]
                             },
                             {
                               :==,
                               [],
                               [{{:., [], [{:&, [], [0]}, :name]}, [], []}, {:^, [], [2]}]
                             }
                           ]
                         }
                       ]
                     },
                     # range wheres
                     {
                       :and,
                       [],
                       [
                         {:>, [], [{{:., [], [{:&, [], [0]}, :age]}, [], []}, {:^, [], [3]}]},
                         {:<, [], [{{:., [], [{:&, [], [0]}, :age]}, [], []}, {:^, [], [4]}]}
                       ]
                     }
                   ]
                 },
                 params: [
                   {20, {0, :age}},
                   {60, {0, :age}},
                   {"Alice", {0, :name}},
                   {20, {0, :age}},
                   {60, {0, :age}}
                 ]
               }
             ]
           } = Query.paginate(User, config)
  end
end
