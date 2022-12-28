defmodule JetExt.Absinthe.Relay.Connection.QueryTest do
  use ExUnit.Case, async: true

  alias JetExt.Absinthe.Relay.Connection.Config
  alias JetExt.Absinthe.Relay.Connection.Query

  defmodule Post do
    use Ecto.Schema

    schema "posts" do
      field :title, :string
      field :content, :string

      timestamps()
    end
  end

  test "works" do
    config =
      Config.new(
        after: %{inserted_at: DateTime.utc_now(), title: "title"},
        direction: :forward,
        cursor_fields: [inserted_at: :asc, title: :asc]
      )

    assert %Ecto.Query{
             from: %{source: {"posts", Post}},
             limit: %{params: [{51, :integer}]},
             order_bys: [
               %{
                 expr: [
                   asc: {{:., [], [{:&, [], [0]}, :inserted_at]}, [], []},
                   asc: {{:., [], [{:&, [], [0]}, :title]}, [], []}
                 ]
               }
             ],
             wheres: [
               %{
                 expr: {
                   :or,
                   [],
                   [
                     {:>, [], [{{:., [], [{:&, [], [0]}, :inserted_at]}, [], []}, {:^, [], [0]}]},
                     {:and, [],
                      [
                        {:>, [], [{{:., [], [{:&, [], [0]}, :title]}, [], []}, {:^, [], [1]}]},
                        {:==, [],
                         [{{:., [], [{:&, [], [0]}, :inserted_at]}, [], []}, {:^, [], [2]}]}
                      ]}
                   ]
                 }
               }
             ]
           } = Query.paginate(Post, config)
  end
end
