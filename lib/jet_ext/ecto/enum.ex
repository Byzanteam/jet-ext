defmodule JetExt.Ecto.Enum do
  @moduledoc """
  Defining an Enum Ecto type.

  ## Parameterized Type

    ```elixir
    iex> type = Ecto.ParameterizedType.init(JetExt.Ecto.Enum, values: [:foo, :bar])
    {
      :parameterized,
      {
        JetExt.Ecto.Enum,
        %{
          on_load: %{"BAR" => :bar, "FOO" => :foo},
          type: :string,
          on_cast: %{"BAR" => :bar, "FOO" => :foo, "bar" => :bar, "foo" => :foo},
          embed_as: :self,
          mappings: [foo: "foo", bar: "bar"],
          on_dump: %{foo: "FOO", bar: "BAR"}
        }
      }
    }
    ```

  ## Type Module

    ```elixir
    defmodule EnumType do
      use JetExt.Ecto.Enum, [:foo, :bar, :baz]
    end
    ```

      # cast
      iex> EnumType.cast("foo")
      {:ok, :foo}
      iex> EnumType.cast("FOO")
      {:ok, :foo}
      iex> EnumType.cast(:foo)
      {:ok, :foo}

      # load
      iex> EnumType.load("foo")
      {:ok, :foo}
      iex> EnumType.load("FOO")
      {:ok, :foo}

      # dump
      iex> EnumType.dump(:foo)
      {:ok, "FOO"}
  """

  use Ecto.ParameterizedType

  @type t() :: atom()

  @impl Ecto.ParameterizedType
  def init(opts) do
    case Ecto.Enum.init(opts) do
      %{type: :integer} = params ->
        params

      %{type: :string} = params ->
        params
        |> Map.update!(
          :on_cast,
          &Enum.reduce(&1, &1, fn {data, value}, on_cast ->
            Map.put(on_cast, String.upcase(data), value)
          end)
        )
        |> Map.update!(
          :on_dump,
          &Map.new(&1, fn {value, data} -> {value, String.upcase(data)} end)
        )
        |> Map.update!(
          :on_load,
          &Map.new(&1, fn {data, value} -> {String.upcase(data), value} end)
        )
    end
  end

  @impl Ecto.ParameterizedType
  def type(params), do: params.type

  @impl Ecto.ParameterizedType
  defdelegate cast(data, params), to: Ecto.Enum

  @impl Ecto.ParameterizedType
  defdelegate dump(data, dumper, params), to: Ecto.Enum

  @impl Ecto.ParameterizedType
  defdelegate load(data, loader, params), to: Ecto.Enum

  @impl Ecto.ParameterizedType
  defdelegate embed_as(format, params), to: Ecto.Enum

  @doc "Returns the possible dump values for a given schema and field"
  @spec dump_values(module(), atom()) :: [String.t()] | [integer()]
  def dump_values(schema, field) do
    # the order of map keys is not guaranteed when iterating over a map
    on_dump = fetch_parameter!(schema, field, :on_dump)
    mappings = fetch_parameter!(schema, field, :mappings)

    Enum.map(mappings, fn {key, _value} ->
      Map.fetch!(on_dump, key)
    end)
  end

  @doc "Returns the mappings for a given schema and field"
  @spec mappings(module(), atom()) :: Keyword.t()
  def mappings(schema, field) do
    fetch_parameter!(schema, field, :mappings)
  end

  @doc "Returns the possible values for a given schema and field"
  @spec values(module, atom) :: [atom()]
  def values(schema, field) do
    schema
    |> mappings(field)
    |> Keyword.keys()
  end

  defmacro __using__(values) do
    quote location: :keep, bind_quoted: [values: values] do
      unless is_list(values) and Enum.all?(values, &is_atom/1) do
        raise ArgumentError, """
        Types using `JetExt.Ecto.Enum` must have a values option specified as
        a list of atoms. For example: `use JetExt.Ecto.Enum, [:foo, :bar]`
        """
      end

      typespec = JetExt.Types.make_sum_type(values)

      use Ecto.Type

      @type t() :: unquote(typespec)

      @cast_mapping Enum.reduce(values, %{}, fn value, acc ->
                      acc
                      |> Map.put(Atom.to_string(value), value)
                      |> Map.put(value |> Atom.to_string() |> String.upcase(), value)
                    end)

      @load_mapping Map.new(values, fn value ->
                      {value,
                       [Atom.to_string(value), value |> Atom.to_string() |> String.upcase()]}
                    end)

      @dump_mapping Map.new(values, &{&1, &1 |> Atom.to_string() |> String.upcase()})

      @impl Ecto.Type
      def type, do: :string

      @impl Ecto.Type
      def cast(nil), do: {:ok, nil}

      @impl Ecto.Type
      def cast(data) do
        case {@cast_mapping, @dump_mapping} do
          {%{^data => as_atom}, _} -> {:ok, as_atom}
          {_, %{^data => _}} -> {:ok, data}
          _otherwise -> :error
        end
      end

      @impl Ecto.Type
      def load(nil), do: {:ok, nil}

      @impl Ecto.Type
      for {as_atom, values} <- @load_mapping do
        def load(unquote(as_atom)), do: {:ok, unquote(as_atom)}

        for value <- values do
          def load(unquote(value)), do: {:ok, unquote(as_atom)}
        end
      end

      def load(_term), do: :error

      @impl Ecto.Type
      def dump(nil), do: {:ok, nil}

      @impl Ecto.Type
      def dump(data) do
        case @dump_mapping do
          %{^data => as_string} -> {:ok, as_string}
          _mapping -> :error
        end
      end

      @impl Ecto.Type
      def embed_as(_data), do: :dump

      # Reflections
      @spec __values__() :: [t(), ...]
      def __values__, do: unquote(values)

      @spec cast!(data :: term()) :: t()
      def cast!(data) do
        case cast(data) do
          {:ok, value} -> value
          :error -> raise RuntimeError, "can't cast `#{data}` to `#{inspect(__MODULE__)}`."
        end
      end

      @spec load!(data :: term()) :: t() | nil
      def load!(data) do
        case load(data) do
          {:ok, value} -> value
          :error -> raise RuntimeError, "can't load `#{data}` as`#{inspect(__MODULE__)}`."
        end
      end

      @spec dump!(data :: t()) :: String.t() | nil
      def dump!(data) do
        case dump(data) do
          {:ok, value} -> value
          :error -> raise RuntimeError, "can't dump `#{data}` as `#{inspect(__MODULE__)}`."
        end
      end
    end
  end

  defp fetch_parameter!(schema, field, name) do
    schema.__changeset__()
  rescue
    _exception in UndefinedFunctionError ->
      raise ArgumentError, "#{inspect(schema)} is not an Ecto schema"
  else
    %{^field => {:parameterized, {__MODULE__, %{^name => value}}}} -> value
    %{^field => {_, {:parameterized, {__MODULE__, %{^name => value}}}}} -> value
    %{^field => _} -> raise ArgumentError, "#{field} is not an #{__MODULE__} field"
    %{} -> raise ArgumentError, "#{field} does not exist"
  end
end
