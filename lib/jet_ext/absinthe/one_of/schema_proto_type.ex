if Code.ensure_loaded?(Absinthe) do
  defmodule JetExt.Absinthe.OneOf.SchemaProtoType do
    @moduledoc """
    ## 使用方法
    在你的 schema 中添加下面代码：
    ```elixir
    defmodule MyApp.Schema.Admin do
      use Absinthe.Schema

      # 添加这一行
      @prototype_schema JetExt.Absinthe.OneOf.SchemaProtoType

      # ...
    end
    ```
    """

    use Absinthe.Schema.Prototype

    directive :one_of do
      on [:input_object]

      expand fn _args, node ->
        %{node | __private__: Keyword.put(node.__private__, :one_of, true)}
      end
    end
  end
end
