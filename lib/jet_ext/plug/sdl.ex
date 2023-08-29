if Code.ensure_loaded?(Plug) and Code.ensure_loaded?(Absinthe) do
  defmodule JetExt.Plug.SDL do
    @moduledoc """
    A plug for serving sdl file.

    It requires one option:
    - `schema`: the Absinthe.Schema module.

    ```elixir
    forward "/graphql.sdl", JetExt.Plug.SDL,
      schema: MyGraphQL.Schema
    ```
    """

    @behaviour Plug

    import Plug.Conn

    @impl Plug
    def init(opts) do
      schema = Keyword.fetch!(opts, :schema)

      unless Code.ensure_loaded?(schema) do
        raise ArgumentError,
              """
              The schema module #{inspect(schema)} is not loaded.
              """
      end

      [schema: schema]
    end

    @impl Plug
    def call(conn, opts) do
      schema = Keyword.fetch!(opts, :schema)

      sdl = Absinthe.Schema.to_sdl(schema)

      conn
      |> put_resp_content_type("text/plain")
      |> resp(200, sdl)
      |> send_resp()
      |> halt()
    end
  end
end
