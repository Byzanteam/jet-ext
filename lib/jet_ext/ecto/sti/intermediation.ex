defmodule JetExt.Ecto.STI.Intermediation do
  @moduledoc false

  alias JetExt.Ecto.STI.IntermediateModule

  @type type_fields() :: Keyword.t(JetExt.Ecto.Enum.t())

  defmacro __using__(opts) do
    type_fields = Keyword.fetch!(opts, :type_fields)
    naming_module = Keyword.fetch!(opts, :naming_module)

    quote location: :keep,
          bind_quoted: [
            type_fields: type_fields,
            naming_module: naming_module
          ] do
      @behaviour IntermediateModule

      alias JetExt.Ecto.STI.Intermediation

      @type_fields type_fields
      @naming_module naming_module

      @impl IntermediateModule
      for module <- @naming_module.modules() do
        def cast(data) when is_struct(data, unquote(module)) do
          {:ok, data}
        end
      end

      def cast(data) when is_map(data) do
        Intermediation.cast(@naming_module, data, @type_fields)
      end

      @impl IntermediateModule
      for module <- @naming_module.modules() do
        def dump(data) when is_struct(data, unquote(module)) do
          @naming_module
          |> Intermediation.dump_token(unquote(module), @type_fields)
          |> Map.merge(Ecto.embedded_dump(data, :json))
          |> then(&{:ok, &1})
        end
      end

      def dump(_data), do: :error

      @impl IntermediateModule
      def load(data) do
        with {:ok, token} <- Intermediation.fetch_token(@naming_module, data, @type_fields),
             {:ok, module} <- @naming_module.resolve_module(token) do
          {:ok, Ecto.embedded_load(module, data, :json)}
        else
          _error -> :error
        end
      end

      defoverridable IntermediateModule
    end
  end

  @spec cast(
          naming_module :: module(),
          data :: map(),
          type_fields :: type_fields()
        ) :: {:ok, Ecto.Changeset.t()} | :error
  def cast(naming_module, data, type_fields) do
    with {:ok, token} <- fetch_token(naming_module, data, type_fields),
         {:ok, module} <- naming_module.resolve_module(token) do
      {:ok, module.changeset(struct!(module), data)}
    end
  end

  @spec fetch_token(naming_module :: module(), data :: map(), type_fields :: type_fields()) ::
          {:ok, tuple()} | :error
  def fetch_token(naming_module, data, type_fields) do
    with {:ok, token} <- cast_token(data, type_fields),
         {:ok, token} <- unwrap_token(token) do
      validate_token(naming_module, token)
    end
  end

  @spec dump_token(naming_module :: module(), module :: module(), type_fields :: type_fields()) ::
          map()
  def dump_token(naming_module, module, type_fields) do
    with {:ok, token} <- naming_module.resolve_token(module),
         {:ok, token} <- wrap_token(token) do
      type_fields
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {{field, type}, index}, result ->
        {:ok, value} = Ecto.Type.dump(type, elem(token, index))
        Map.put(result, field, value)
      end)
    end
  end

  defp cast_token(data, type_fields) do
    field_names = Keyword.keys(type_fields)

    Enum.reduce_while(type_fields, {:ok, {}}, fn {field, type}, {:ok, token} ->
      with {:ok, raw_type} <- fetch_type(data, field),
           {:ok, casted_type} <- cast_type(type, raw_type) do
        {:cont, {:ok, Tuple.append(token, casted_type)}}
      else
        {:error, :type_absence} ->
          {:halt, {:error, {:type_absence, field_names}}}

        {:error, :unexpected_type} ->
          {:halt, {:error, {:unexpected_type, field_names}}}
      end
    end)
  end

  defp fetch_type(data, field) do
    with :error <- JetExt.Map.indifferent_fetch(data, field) do
      {:error, :type_absence}
    end
  end

  defp cast_type(type, value) do
    with :error <- Ecto.Type.cast(type, value) do
      {:error, :unexpected_type}
    end
  end

  defp validate_token(naming_module, token) do
    if token in naming_module.tokens(), do: {:ok, token}, else: :error
  end

  defp unwrap_token({token}), do: {:ok, token}
  defp unwrap_token(token), do: {:ok, token}

  defp wrap_token(token) when is_tuple(token), do: {:ok, token}
  defp wrap_token(token), do: {:ok, {token}}
end
