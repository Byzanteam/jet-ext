defmodule JetExt.Ecto.STI.IntermediateModule do
  @moduledoc """
  A behaviour module for implementing a STI Ecto type.
  """

  @typep field_name() :: atom()

  @typep expected_values() :: list(atom())

  @callback cast(data :: map()) ::
              {:ok, struct()}
              | {:ok, Ecto.Changeset.t()}
              | {:error, {:type_absence, field_name() | list(field_name())}}
              | {:error, {:unexpected_type, list({field_name(), expected_values()})}}

  @callback dump(data :: struct()) :: {:ok, map()} | :error

  @callback load(data :: map()) :: {:ok, struct()} | :error
end
