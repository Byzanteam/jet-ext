defmodule JetExt.Ecto.STI.Parameterized do
  @moduledoc """
  The parameterized STI type.

  ```
    field :bar, JetExt.Ecto.STI.Parameterized, intermediate_module: MyIntermediaModule
  ```
  """

  use Ecto.ParameterizedType

  alias JetExt.Ecto.STI.Builder

  defstruct [
    :intermediate_module
  ]

  @impl Ecto.ParameterizedType
  def type(_params), do: :map

  @impl Ecto.ParameterizedType
  def init(opts) do
    intermediate_module = Keyword.fetch!(opts, :intermediate_module)

    struct!(__MODULE__, intermediate_module: intermediate_module)
  end

  @impl Ecto.ParameterizedType
  def embed_as(_format, _params), do: :dump

  @impl Ecto.ParameterizedType
  def load(nil, _loader, _params), do: {:ok, nil}

  def load(value, _loader, %{intermediate_module: intermediate_module}) do
    Builder.__load__(intermediate_module, value)
  end

  @impl Ecto.ParameterizedType
  def dump(nil, _dumper, _params), do: {:ok, nil}

  def dump(value, _dumper, %{intermediate_module: intermediate_module}) do
    Builder.__dump__(intermediate_module, value)
  end

  @impl Ecto.ParameterizedType
  def cast(nil, _params), do: {:ok, nil}

  def cast(value, %{intermediate_module: intermediate_module}) do
    Builder.__cast__(intermediate_module, value)
  end

  @spec intermediate_module(Ecto.Schema.t(), atom()) :: module()
  def intermediate_module(schema, field) do
    schema.__changeset__()
  rescue
    _error in UndefinedFunctionError ->
      raise ArgumentError, "#{inspect(schema)} is not an Ecto schema"
  else
    %{^field => {:parameterized, __MODULE__, %{intermediate_module: intermediate_module}}} ->
      intermediate_module

    %{^field => {_, {:parameterized, __MODULE__, %{intermediate_module: intermediate_module}}}} ->
      intermediate_module

    %{^field => _} ->
      raise ArgumentError, "#{field} is not an #{inspect(__MODULE__)} field"

    %{} ->
      raise ArgumentError, "#{field} does not exist"
  end
end
