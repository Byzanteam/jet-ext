defmodule JetExt.Plug.SDLTest do
  use ExUnit.Case, async: true
  use Plug.Test

  defmodule MySchema do
    use Absinthe.Schema

    # Example data
    @items %{
      "foo" => %{id: "foo", name: "Foo"},
      "bar" => %{id: "bar", name: "Bar"}
    }

    object :item do
      field(:id, non_null(:string))
      field(:name, non_null(:string))
    end

    query do
      field :item, :item do
        arg(:id, non_null(:id))

        resolve(fn %{id: item_id}, _res ->
          {:ok, @items[item_id]}
        end)
      end
    end
  end

  test "returns hello world" do
    conn = conn(:get, "/graphql.sdl")

    conn = call(conn, schema: MySchema)

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]

    assert conn.resp_body == """
           schema {
             query: RootQueryType
           }

           type Item {
             id: String!
             name: String!
           }

           type RootQueryType {
             item(id: ID!): Item
           }
           """
  end

  defp call(conn, opts) do
    opts = JetExt.Plug.SDL.init(opts)

    JetExt.Plug.SDL.call(conn, opts)
  end
end
