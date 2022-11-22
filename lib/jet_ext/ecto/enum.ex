defmodule JetExt.Ecto.Enum do
  @moduledoc """
  Defining an Enum Ecto type.

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

  @type t() :: atom()

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
      @spec __values__() :: [t()]
      def __values__, do: unquote(values)

      @spec cast!(data :: term()) :: t()
      def cast!(data) do
        case cast(data) do
          {:ok, value} -> value
          :error -> raise RuntimeError, "can't cast `#{data}` to `#{inspect(__MODULE__)}`."
        end
      end

      @spec load!(data :: term()) :: t()
      def load!(data) do
        case load(data) do
          {:ok, value} -> value
          :error -> raise RuntimeError, "can't load `#{data}` as`#{inspect(__MODULE__)}`."
        end
      end

      @spec dump!(data :: t()) :: map() | nil
      def dump!(data) do
        case dump(data) do
          {:ok, value} -> value
          :error -> raise RuntimeError, "can't dump `#{data}` as `#{inspect(__MODULE__)}`."
        end
      end
    end
  end
end
