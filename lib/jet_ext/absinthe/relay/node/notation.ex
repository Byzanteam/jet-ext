if Code.ensure_loaded?(Absinthe.Relay) do
  defmodule JetExt.Absinthe.Relay.Node.Notation do
    @moduledoc """
    Macros used to define Node-related schema entities

    See `Absinthe.Relay.Node` for examples of use.

    If you wish to use this module on its own without `use Absinthe.Relay` you
    need to include
    ```
    @pipeline_modifier Absinthe.Relay.Schema
    ```
    in your root schema module.
    """

    alias Absinthe.Blueprint.Schema

    @doc """
    Define a node interface, field, or object type for a schema.

    See the `Absinthe.Relay.Node` module documentation for examples.
    """

    defmacro node({:interface, meta, [attrs]}, do: block) when is_list(attrs) do
      do_interface(meta, attrs, block)
    end

    defmacro node({:interface, meta, attrs}, do: block) do
      do_interface(meta, attrs, block)
    end

    defmacro node({:field, meta, [attrs]}, do: block) when is_list(attrs) do
      do_field(meta, attrs, block)
    end

    defmacro node({:field, meta, attrs}, do: block) do
      do_field(meta, attrs, block)
    end

    defmacro node({:object, meta, [identifier, attrs]}, do: block) when is_list(attrs) do
      do_object(meta, identifier, attrs, block)
    end

    defmacro node({:object, meta, [identifier]}, do: block) do
      do_object(meta, identifier, [], block)
    end

    defp do_interface(meta, attrs, block) do
      attrs = attrs || []
      {id_type, attrs} = Keyword.pop(attrs, :id_type, get_id_type())

      block = [interface_body(id_type), block]
      attrs = [:node | [attrs]]
      # credo:disable-for-next-line Credo.Check.Refactor.AppendSingleItem
      {:interface, meta, attrs ++ [[do: block]]}
    end

    defp do_field(meta, attrs, block) do
      attrs = attrs || []
      {id_type, attrs} = Keyword.pop(attrs, :id_type, get_id_type())

      # credo:disable-for-next-line Credo.Check.Refactor.AppendSingleItem
      {:field, meta, [:node, :node, attrs ++ [do: [field_body(id_type), block]]]}
    end

    defp do_object(meta, identifier, attrs, block) do
      {id_fetcher, attrs} = Keyword.pop(attrs, :id_fetcher)
      {id_type, attrs} = Keyword.pop(attrs, :id_type, get_id_type())

      block = [
        quote do
          private(:absinthe_relay, :node, {:fill, unquote(__MODULE__)})
          private(:absinthe_relay, :id_fetcher, unquote(id_fetcher))
        end,
        object_body(id_fetcher, id_type),
        block
      ]

      # credo:disable-for-next-line Credo.Check.Refactor.AppendSingleItem
      {:object, meta, [identifier, attrs] ++ [[do: block]]}
    end

    @spec additional_types(term(), term()) :: []
    # credo:disable-for-next-line Credo.Check.Consistency.UnusedVariableNames
    def additional_types(_, _), do: []

    # def fillout(:node, %Schema.ObjectTypeDefinition{} = obj) do
    #   id_field = id_field_template() |> Map.put(:middleware, [])

    #   %{obj | interfaces: [:node | obj.interfaces], fields: [id_field | obj.fields]}
    # end

    @spec fillout(term(), obj_or_node) :: obj_or_node when obj_or_node: var
    def fillout(_interface, %Schema.ObjectTypeDefinition{identifier: :faction} = obj) do
      obj
    end

    def fillout(_interface, node) do
      node
    end

    defp get_id_type do
      Application.get_env(Absinthe.Relay, :node_id_type, :id)
    end

    # A node id field is automatically configured
    defp interface_body(id_type) do
      quote do
        field(:node_id, non_null(unquote(id_type)), description: "The ID of the object.")
      end
    end

    # A node id arg is automatically added
    defp field_body(id_type) do
      quote do
        @desc "The ID of an object."
        arg(:node_id, non_null(unquote(id_type)))

        middleware({JetExt.Absinthe.Relay.Node.Notation, :resolve_with_global_id})
      end
    end

    # Automatically add:
    # - A node id field that resolves to the generated global ID
    #   for an object of this type
    # - A declaration that this implements the node interface
    defp object_body(id_fetcher, id_type) do
      quote do
        @desc "The ID of an object"
        field :node_id, non_null(unquote(id_type)) do
          middleware {Absinthe.Relay.Node, :global_id_resolver}, unquote(id_fetcher)
        end

        interface(:node)
      end
    end

    @spec resolve_with_global_id(Absinthe.Resolution.t(), term()) ::
            Absinthe.Resolution.t()
    def resolve_with_global_id(
          %{state: :unresolved, arguments: %{node_id: global_id}} = res,
          _opts
        ) do
      case Absinthe.Relay.Node.from_global_id(global_id, res.schema) do
        {:ok, result} ->
          %{res | arguments: result}

        error ->
          Absinthe.Resolution.put_result(res, error)
      end
    end

    def resolve_with_global_id(res, _opts) do
      res
    end
  end
end
