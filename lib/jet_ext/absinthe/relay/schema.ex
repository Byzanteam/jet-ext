if Code.ensure_loaded?(Absinthe.Relay) do
  defmodule JetExt.Absinthe.Relay.Schema do
    @moduledoc """
    Used to extend a schema with Relay-specific macros and types.

    See `Absinthe.Relay`.
    """

    defmacro __using__(flavor) when is_atom(flavor) do
      do_using(flavor, [])
    end

    defmacro __using__(opts) when is_list(opts) do
      opts
      |> Keyword.get(:flavor, [])
      |> do_using(opts)
    end

    defp do_using(flavor, opts) do
      quote do
        @pipeline_modifier unquote(__MODULE__)
        use JetExt.Absinthe.Relay.Schema.Notation, unquote(flavor)
        import_types Absinthe.Relay.Connection.Types

        @spec __absinthe_relay_global_id_translator__() :: module()
        def __absinthe_relay_global_id_translator__ do
          Keyword.get(unquote(opts), :global_id_translator)
        end
      end
    end

    @spec pipeline(Absinthe.Pipeline.t()) :: Absinthe.Pipeline.t()
    def pipeline(pipeline) do
      Absinthe.Pipeline.insert_before(
        pipeline,
        Absinthe.Phase.Schema.ApplyDeclaration,
        Absinthe.Relay.Schema.Phase
      )
    end
  end
end
