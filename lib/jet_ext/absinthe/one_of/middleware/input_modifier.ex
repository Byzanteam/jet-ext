if Code.ensure_loaded?(Absinthe) do
  defmodule JetExt.Absinthe.OneOf.Middleware.InputModifier do
    @moduledoc """
    ## 使用方法
    ```elixir
    defmodule MyApp.GraphQL.Schema.Admin do
      @moduledoc false

      use Absinthe.Schema.Notation
      use Absinthe.Relay.Schema.Notation, :modern

      alias Absinthe.Blueprint.Input
      alias JetExt.Absinthe.OneOf.Helpers

      input_object :user_input do
        # 首先启用 :one_of directive
        directive :one_of

        # 使用 Helpers 提供的 input_modifier
        private(
          :input_modifier,
          :with,
          {Helpers, :fold_key_to_field, [:__type__]}
        )

        field :plain_user, :plain_user_input
        field :admin, :admin_input
      end

      input_object :plain_user_input do
        field :username, non_null(:string)
      end

      input_object :admin_input do
        field :role, non_null(:string)
      end

      object :mutations do
        payload field(:create_user) do
          input do
            field :attributes, non_null(list_of(non_null(:user_input)))
          end

          output do
            field :attributes, non_null(list_of(non_null(:user)))
          end

          # 在 input 使用了 one_of 后，再启用本 middleware
          middleware JetExt.Absinthe.OneOf.Middleware.InputModifier

          resolve &create_user/2
        end
      end

      defp create_user(args, _resolution) do
        IO.inspect(args)
        # 前端会这样调用：
        # mutation {
        #   createUser(input: {
        #     plainUser: { username: "foo" }
        #   }) {
        #     id
        #   }
        # }
        #
        # 我们这里拿到的 args 是（注意 plain_user 是从驼峰转成了蛇底的）：
        # %{
        #   username: "foo",
        #   "__type__": "plain_user"
        # }
      end
    end
    ``
    """

    @behaviour Absinthe.Middleware

    alias Absinthe.Blueprint.Input

    @impl Absinthe.Middleware
    def call(%Absinthe.Resolution{state: :unresolved} = res, _opts) do
      case extract_argument_defs(res) do
        {:ok, input_objects = [_ | _]} ->
          arguments = modify_inputs(res.arguments, input_objects)
          %{res | arguments: arguments}

        {:ok, input_object} ->
          arguments = modify_input(res.arguments, input_object)
          %{res | arguments: arguments}

        :error ->
          res
      end
    end

    def call(%Absinthe.Resolution{} = res, _opts), do: res

    # relay 风格的参数需要特殊处理一下，因为 relay 会提前对它进行特殊处理，
    # 把 %{input: arguments} 变成 arguments
    defp extract_argument_defs(%Absinthe.Resolution{
           definition: %Absinthe.Blueprint.Document.Field{
             arguments: [
               %Input.Argument{name: "input", input_value: %Input.Value{normalized: input_object}}
             ]
           }
         }) do
      {:ok, input_object}
    end

    defp extract_argument_defs(%Absinthe.Resolution{
           definition: %Absinthe.Blueprint.Document.Field{arguments: [_ | _] = arguments}
         }) do
      {:ok, Enum.map(arguments, &{Macro.underscore(&1.name), &1.input_value.normalized})}
    end

    defp extract_argument_defs(_resolution), do: :error

    defp modify_inputs(data, input_objects) do
      Map.new(data, fn {key, value} ->
        {_key, input_object} = List.keyfind!(input_objects, Atom.to_string(key), 0)
        {key, modify_input(value, input_object)}
      end)
    end

    defp modify_input(
           data,
           %Input.Object{schema_node: schema_node, fields: fields} = input_object
         ) do
      schema_node = Absinthe.Type.unwrap(schema_node)

      case Keyword.fetch(schema_node.__private__, :input_modifier) do
        {:ok, [with: {:{}, _meta, [mod, fun, args]}]}
        when is_atom(mod) and is_atom(fun) and is_list(args) ->
          {data, input_object} = apply(mod, fun, [data, input_object | args])

          modify_input(data, input_object)

        _otherwise ->
          Map.new(data, &modify_input_object_entry(&1, fields))
      end
    end

    defp modify_input(data, %Input.List{items: items}) do
      [data, items]
      |> Enum.zip()
      |> Enum.map(fn {data, %Input.Value{normalized: input_object}} ->
        modify_input(data, input_object)
      end)
    end

    defp modify_input(data, _input_object), do: data

    defp modify_input_object_entry({key, value}, fields) do
      key_str = key |> to_string() |> Macro.camelize()

      case Enum.find(fields, &(Macro.camelize(&1.name) === key_str)) do
        %Input.Field{input_value: %Input.Value{normalized: input_object}} ->
          {key, modify_input(value, input_object)}

        _otherwise ->
          {key, value}
      end
    end
  end
end
