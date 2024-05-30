if Code.ensure_loaded?(Absinthe) do
  defmodule JetExt.Absinthe.OneOf.Phase do
    @moduledoc """
    The homemade `one_of` phase for Absinthe.

    ## 使用方法
    在 Router 中添加如下代码：
    ```elixir
    defmodule MyApp.Router do
      use Phoenix.Router

      # ...

      scope "/api" do
        pipe_through :api

        forward "/admin/explorer", Absinthe.Plug.GraphiQL,
          interface: :playground,
          schema: MyApp.GraphQL.Schema.Admin,
          # 添加下面这一行
          pipeline: {__MODULE__, :pipeline}

        forward "/admin", Absinthe.Plug,
          json_codec: Jason,
          schema: MyApp.GraphQL.Schema.Admin,
          # 添加下面这一行
          pipeline: {__MODULE__, :pipeline}
      end

      @spec pipeline(map(), keyword()) :: Absinthe.Pipeline.t()
      def pipeline(config, opts) do
        config.schema_mod
        |> Absinthe.Pipeline.for_document(opts)
        |> Absinthe.Pipeline.insert_after(
          Absinthe.Phase.Document.Validation.OnlyOneSubscription,
          JetExt.Absinthe.OneOf.Phase
        )
      end
    end
    ```

    ## 开发笔记
    参考：https://maartenvanvliet.nl/2022/04/28/absinthe_input_union/
    他的方案只能校验最上层的 input_object 的 one_of，因此做了修改能够递归地校验 input_object 下层的 one_of。
    """

    @behaviour Absinthe.Phase

    alias Absinthe.Blueprint.Input

    @impl Absinthe.Phase
    def run(blueprint, _config) do
      {:ok, Absinthe.Blueprint.prewalk(blueprint, &handle_node/1)}
    end

    defp handle_node(%Input.Argument{} = node) do
      if validate_one_of(node) do
        node
      else
        Absinthe.Phase.put_error(node, error(node))
      end
    end

    defp handle_node(node), do: node

    defp validate_one_of(%{input_value: %Input.Value{normalized: %Input.Object{} = input_object}}) do
      schema_node = Absinthe.Type.unwrap(input_object.schema_node)
      private = if(is_nil(schema_node), do: [], else: schema_node.__private__)

      if Keyword.get(private, :one_of, false) and length(input_object.fields) > 1 do
        false
      else
        Enum.all?(input_object.fields, &validate_one_of/1)
      end
    end

    defp validate_one_of(%{input_value: %Input.Value{normalized: %Input.List{items: items}}}) do
      Enum.all?(items, fn item -> validate_one_of(%{input_value: item}) end)
    end

    defp validate_one_of(_node), do: true

    defp error(node) do
      %Absinthe.Phase.Error{
        phase: __MODULE__,
        message: """
        OneOf Object "#{node.name}" must have exactly one non-null field.
        """,
        locations: [node.source_location]
      }
    end
  end
end
