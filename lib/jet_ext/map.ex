defmodule JetExt.Map do
  @moduledoc """
  This module introduces some useful functions to `Map`.

  - `atomize_keys/1`
  """

  @compile {:inline, atomize_keys: 1, recursive_atomize_keys: 1, filter: 2, fetch: 2}

  @doc """
  Atomize keys of map.

  ## Example

    iex> JetExt.Map.atomize_keys(%{"a" => 1, "b" => 2})
    %{a: 1, b: 2}
    iex> JetExt.Map.atomize_keys(%{"a" => 1, "b" => %{"c" => 2}})
    %{a: 1, b: %{"c" => 2}}
    iex> JetExt.Map.atomize_keys(%{"a" => 1, "b" => [%{"c" => 2}, %{"d" => 3}]})
    %{a: 1, b: [%{"c" => 2}, %{"d" => 3}]}
  """
  @spec atomize_keys(map()) :: map()
  def atomize_keys(%_struct{} = data), do: data

  def atomize_keys(%{} = data) do
    Map.new(data, fn
      {k, v} when is_binary(k) ->
        {String.to_existing_atom(k), v}

      {k, v} ->
        {k, v}
    end)
  end

  @doc """
  Stringify keys of map.

  ## Example

    iex> JetExt.Map.stringify_keys(%{a: 1, b: 2})
    %{"a" => 1, "b" => 2}
    iex> JetExt.Map.stringify_keys(%{a: 1, b: %{c: 2}})
    %{"a" => 1, "b" => %{c: 2}}
  """
  @spec stringify_keys(map()) :: map()
  def stringify_keys(%_struct{} = data), do: data

  def stringify_keys(%{} = data) do
    for {key, value} <- data, into: %{} do
      key = if(is_binary(key), do: key, else: to_string(key))
      {key, value}
    end
  end

  @doc """
  Atomize keys of any map nested in the term recursively.

  ## Example

    iex> JetExt.Map.recursive_atomize_keys(%{"a" => 1, "b" => 2})
    %{a: 1, b: 2}
    iex> JetExt.Map.recursive_atomize_keys(%{"a" => 1, "b" => %{"c" => 2}})
    %{a: 1, b: %{c: 2}}
    iex> JetExt.Map.recursive_atomize_keys(%{"a" => [%{"b" => %{"c" => 2}}]})
    %{a: [%{b: %{c: 2}}]}
    iex> JetExt.Map.recursive_atomize_keys(%{"a" => [%{"b" => %{"c" => 2}}], d: true})
    %{a: [%{b: %{c: 2}}], d: true}
    iex> JetExt.Map.recursive_atomize_keys([%{"a" => 1}, "b"])
    [%{a: 1}, "b"]
  """
  @spec recursive_atomize_keys(term()) :: term()
  def recursive_atomize_keys(data) when is_list(data) do
    Enum.map(data, &recursive_atomize_keys(&1))
  end

  def recursive_atomize_keys(%{} = data) when not is_struct(data) do
    for {key, value} <- data, into: %{} do
      key =
        cond do
          is_atom(key) -> key
          # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
          is_binary(key) -> String.to_atom(key)
          true -> key |> to_string() |> String.to_atom()
        end

      {key, recursive_atomize_keys(value)}
    end
  end

  def recursive_atomize_keys(data), do: data

  @doc """
  Filter items of the map.

  ## Example

    iex> JetExt.Map.filter(%{a: 1, b: 2, c: 3, d: 4}, fn {key, value} -> :a === key or 2 === value end)
    %{a: 1, b: 2}
  """
  @spec filter(map(), function()) :: map()
  def filter(%{} = data, filter_funciton) when is_function(filter_funciton, 1) do
    data
    |> Enum.filter(filter_funciton)
    |> Map.new()
  end

  @doc """
  Put a value to map base on key type of the map.

    iex> JetExt.Map.put_field(%{a: 1, b: 2}, :c, 3)
    %{a: 1, b: 2, c: 3}

    iex> JetExt.Map.put_field(%{"a" => 1, "b" => 2}, :c, 3)
    %{"a" => 1, "b" => 2, "c" => 3}

    iex> JetExt.Map.put_field(%{"a" => 1, b: 2}, :c, 3)
    ** (ArgumentError) expected map to be a map with atoms or string keys, got a map with mixed keys: %{:b => 2, "a" => 1}
  """
  @spec put_field(map(), atom(), term()) :: map()
  def put_field(map, key, value) when is_atom(key) do
    cond do
      Enum.all?(map, &match?({key, _} when is_atom(key), &1)) ->
        Map.put(map, key, value)

      Enum.all?(map, &match?({key, _} when is_binary(key), &1)) ->
        Map.put(map, Atom.to_string(key), value)

      true ->
        raise ArgumentError,
              "expected map to be a map with atoms or string keys," <>
                " got a map with mixed keys: #{inspect(map)}"
    end
  end

  @doc """
  Indifferent access, or raise error.

  ## Example

    iex> JetExt.Map.indifferent_fetch!(%{a: 1}, :a)
    1

    iex> JetExt.Map.indifferent_fetch!(%{"a" => 1}, :a)
    1

    iex> JetExt.Map.indifferent_fetch!(%{"a" => 1}, :b)
    ** (KeyError) key :b not found in: %{"a" => 1}
  """
  @spec indifferent_fetch!(map(), key :: atom()) :: term()
  def indifferent_fetch!(map, key) when is_atom(key) do
    case indifferent_fetch(map, key) do
      {:ok, value} -> value
      :error -> raise %KeyError{key: key, term: map}
    end
  end

  @doc """
  Indifferent access, or return `:error`.

  ## Example

    iex> JetExt.Map.indifferent_fetch(%{a: 1}, :a)
    {:ok, 1}

    iex> JetExt.Map.indifferent_fetch(%{"a" => 1}, :a)
    {:ok, 1}

    iex> JetExt.Map.indifferent_fetch(%{"a" => 1}, :b)
    :error
  """
  @spec indifferent_fetch(map(), key :: atom()) :: term()
  def indifferent_fetch(map, key) when is_atom(key) do
    case Map.fetch(map, key) do
      {:ok, _value} = ok -> ok
      :error -> Map.fetch(map, Atom.to_string(key))
    end
  end

  @doc """
  Indifferent take.

  Returns a new map with all the key-value pairs in map where the key, or String.to_atom(key) is in keys.

  ## Example

    iex> JetExt.Map.indifferent_take(%{"a" => 1, "b" => 2, c: 3, d: 4}, [:a, :b, :c])
    %{"a" => 1, "b" => 2, c: 3}

    iex> JetExt.Map.indifferent_take(%{"a" => 1}, [:a])
    %{"a" => 1}

    iex> JetExt.Map.indifferent_take(%{"a" => 1}, [:b])
    %{}
  """
  @spec indifferent_take(map(), keys :: [atom()]) :: map()
  def indifferent_take(map, keys) when is_list(keys) do
    alt_keys =
      for key <- keys, reduce: [] do
        acc ->
          unless is_atom(key), do: raise(KeyError, "key must be a atom")
          str_key = Atom.to_string(key)

          case map do
            %{^key => _value} ->
              [key | acc]

            %{^str_key => _value} ->
              [str_key | acc]

            %{} ->
              acc

            other ->
              :erlang.error({:badmap, other}, [map, key])
          end
      end

    Map.take(map, alt_keys)
  end

  @doc """
  Indifferent updates the key in map with the given function.

  ## Example

    iex> JetExt.Map.indifferent_has_key(%{a: 1}, :a)
    {:ok, :a}

    iex> JetExt.Map.indifferent_has_key(%{"a" => 1}, :a)
    {:ok, "a"}

    iex> JetExt.Map.indifferent_has_key(%{"a" => 1}, :b)
    :error
  """
  @spec indifferent_has_key(map(), key :: atom()) :: {:ok, binary() | atom()} | :error
  def indifferent_has_key(map, key) when is_atom(key) do
    str_key = Atom.to_string(key)

    case map do
      %{^key => _value} ->
        {:ok, key}

      %{^str_key => _value} ->
        {:ok, str_key}

      %{} ->
        :error

      other ->
        :erlang.error({:badmap, other}, [map, key])
    end
  end

  @doc """
  Indifferent updates the key in map with the given function.

  If `key` is not present in `map`, a `KeyError` exception is raised.

  ## Example

    iex> JetExt.Map.indifferent_update!(%{a: 1}, :a, fn val -> val + 1 end)
    %{a: 2}

    iex> JetExt.Map.indifferent_update!(%{"a" => 1}, :a, fn val -> val + 1 end)
    %{"a" => 2}

    iex> JetExt.Map.indifferent_update!(%{"a" => 1}, :b, fn val -> val + 1 end)
    ** (KeyError) key :b and "b" not found in: %{"a" => 1}
  """
  @spec indifferent_update!(
          map(),
          key :: atom(),
          (existing_value :: value -> new_value :: value)
        ) :: map()
        when value: term()
  def indifferent_update!(map, key, fun) when is_atom(key) do
    str_key = Atom.to_string(key)

    case map do
      %{^key => value} ->
        %{map | key => fun.(value)}

      %{^str_key => value} ->
        %{map | str_key => fun.(value)}

      %{} ->
        raise KeyError,
              "key #{inspect(key)} and #{inspect(str_key)} not found in: #{inspect(map)}"

      other ->
        :erlang.error({:badmap, other}, [map, key, fun])
    end
  end

  @doc """
  Indifferent access, or return default value.

  ## Example

    iex> JetExt.Map.indifferent_get(%{a: 1}, :a)
    1

    iex> JetExt.Map.indifferent_get(%{"a" => 1}, :a)
    1

    iex> JetExt.Map.indifferent_get(%{"a" => 1}, :b)
    nil

    iex> JetExt.Map.indifferent_get(%{"a" => 1}, :b, 2)
    2

    iex> JetExt.Map.indifferent_get(%{"a" => 1}, "a")
    1
  """
  @spec indifferent_get(map(), key :: atom(), default :: term()) :: term()
  def indifferent_get(map, key, default \\ nil)

  def indifferent_get(map, key, default) when is_binary(key) do
    indifferent_get(map, String.to_existing_atom(key), default)
  end

  def indifferent_get(map, key, default) when is_atom(key) do
    Map.get_lazy(map, key, fn ->
      Map.get(map, Atom.to_string(key), default)
    end)
  end

  @doc """
  Fetches the value in form of key tuple for a specific key in the given map.

  ## Example

    iex> JetExt.Map.fetch(%{a: 1, b: nil}, :a)
    {:a, {:ok, 1}}
    iex> JetExt.Map.fetch(%{a: 1, b: nil}, :b)
    {:b, {:ok, nil}}
    iex> JetExt.Map.fetch(%{a: 1, b: nil}, :c)
    {:c, :error}
  """
  @spec fetch(map(), key) :: {key, {:ok, term()} | :error} when key: term()
  def fetch(map, key) do
    {key, Map.fetch(map, key)}
  end
end
