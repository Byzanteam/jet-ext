defmodule JetExt.Ecto.STI.Builder do
  @moduledoc """
  Defines the STI like Ecto types.
  """

  alias JetExt.Ecto.STI.Changeset
  alias JetExt.Ecto.STI.Logger

  @typep using_opts() :: [intermediate_module: module()]

  @spec __using__(opts :: using_opts()) :: Macro.t()
  defmacro __using__(opts) do
    intermediate_module = Keyword.fetch!(opts, :intermediate_module)

    quote location: :keep do
      @before_compile JetExt.Ecto.STI.Builder

      Code.ensure_compiled!(unquote(intermediate_module))

      use Ecto.Type

      @impl Ecto.Type
      def type, do: :map

      @impl Ecto.Type
      def embed_as(_format), do: :dump

      @impl Ecto.Type
      def cast(data) when is_map(data) do
        data
        |> unquote(intermediate_module).cast()
        |> case do
          {:ok, %Ecto.Changeset{valid?: true} = changeset} ->
            {:ok, Ecto.Changeset.apply_changes(changeset)}

          {:ok, %Ecto.Changeset{valid?: false} = changeset} ->
            {:error, [validation: :sti, sti_errors: Changeset.collect_errors(changeset)]}

          {:ok, data} when is_struct(data) ->
            {:ok, data}

          {:error, {:type_absence, field_names}} ->
            field_names = List.wrap(field_names)

            Logger.log_cast_error(
              __MODULE__,
              data,
              "#{inspect(field_names)} are required"
            )

            errors = Map.new(field_names, &{&1, [{"can't be blank", validation: :required}]})

            {:error, [validation: :sti, sti_errors: errors]}

          {:error, {:unexpected_type, fields}} ->
            fields = List.wrap(fields)

            details =
              Enum.map_join(fields, "\n", fn {field_name, expected_values} ->
                "#{inspect(field_name)} expected values: #{inspect(expected_values)}"
              end)

            Logger.log_cast_error(
              __MODULE__,
              data,
              """
              unexpected type
              #{inspect(details)}
              """
            )

            errors =
              Map.new(fields, fn {field_name, expected_values} ->
                {field_name, [{"is invalid", validation: :inclusion, enum: expected_values}]}
              end)

            {:error, [validation: :sti, sti_errors: errors]}
        end
      end

      def cast(data) do
        Logger.log_cast_error(__MODULE__, data, "expected data is map")

        :error
      end

      @impl Ecto.Type
      def dump(data) when is_struct(data) do
        data
        |> unquote(intermediate_module).dump()
        |> case do
          {:ok, result} ->
            {:ok, result}

          :error ->
            Logger.log_dump_error(__MODULE__, data)
            :error
        end
      end

      def dump(data) do
        Logger.log_dump_error(__MODULE__, data)

        :error
      end

      @impl Ecto.Type
      def load(data) when is_map(data) do
        data
        |> unquote(intermediate_module).load()
        |> case do
          {:ok, data} ->
            {:ok, data}

          :error ->
            Logger.log_load_error(__MODULE__, data)

            :error
        end
      end

      def load(data) do
        Logger.log_load_error(__MODULE__, data)

        :error
      end
    end
  end

  defmacro __before_compile__(env) do
    unless Module.defines_type?(env.module, {:t, 0}) do
      raise ArgumentError, """
      The `:t` type is not defined.

      ## Example:

          @type t() :: %__MODULE__{}
      """
    end

    quote location: :keep do
      @spec load!(map()) :: t()
      def load!(params) do
        case load(params) do
          {:ok, data} ->
            data

          :error ->
            raise RuntimeError, "Cannot load #{inspect(params)} for #{inspect(__MODULE__)}."
        end
      end

      @spec dump!(t()) :: map()
      def dump!(data) do
        case dump(data) do
          {:ok, params} ->
            params

          :error ->
            raise RuntimeError, "Cannot dump #{inspect(data)} for #{inspect(__MODULE__)}."
        end
      end
    end
  end
end
