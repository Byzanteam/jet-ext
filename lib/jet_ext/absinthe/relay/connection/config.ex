if Code.ensure_loaded?(Absinthe.Relay) do
  defmodule JetExt.Absinthe.Relay.Connection.Config do
    @moduledoc false

    @type t :: %__MODULE__{}

    defstruct [
      :direction,
      :after,
      :before,
      :limit,
      cursor_fields: [],
      # include head and tail
      include_head_edge: false,
      include_tail_edge: false
    ]

    @default_limit 50
    @minimum_limit 1
    @maximum_limit 500

    @spec new(keyword()) :: t()
    def new(opts \\ []) do
      struct(__MODULE__, Keyword.put(opts, :limit, limit(opts)))
    end

    defp limit(opts) do
      min(
        max(opts[:limit] || @default_limit, @minimum_limit),
        opts[:maximum_limit] || @maximum_limit
      )
    end

    @spec disable_edge_including(t()) :: t()
    def disable_edge_including(%__MODULE__{} = config) do
      %{config | include_head_edge: false, include_tail_edge: false}
    end
  end
end
