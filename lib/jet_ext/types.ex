defmodule JetExt.Types do
  @moduledoc """
  Define types that used in the jet projects.
  """

  @type maybe(t) :: t | nil

  @typedoc """
  Used to declare the key of a `Keyword` as mandatory.

  NOTE: It can only be used on the type of the value.

  ```elixir
  @type options() :: [
    required_key: as_required(boolean()),
    optional_key: boolean()
  ]
  ```
  """
  @type as_required(t) :: t

  @doc """
  Make [sum type](https://en.wikipedia.org/wiki/Tagged_union).

      iex> JetExt.Types.make_sum_type([:foo, :bar, :baz])
      quote do :foo | :bar | :baz end
  """
  @spec make_sum_type([atom(), ...]) :: Macro.t()
  def make_sum_type(types) do
    types
    |> Enum.reverse()
    |> Enum.reduce(fn type, acc when is_atom(type) ->
      add_type(type, acc)
    end)
  end

  @doc """
  Make sum type from a list of modules.

    ```elixir
    defmodule Foo do
      @type t() :: :foo
    end
    defmodule Bar do
      @type t() :: :bar
    end
    defmodule Baz do
      @type t() :: :baz
    end
    ```

      iex> JetExt.Types.make_module_sum_type([Foo, Bar, Baz], :t)
  """
  @spec make_module_sum_type([module(), ...], atom()) :: Macro.t()
  def make_module_sum_type(modules, type) do
    modules
    |> Enum.map(fn module ->
      quote do: unquote(module).unquote(type)()
    end)
    |> Enum.reverse()
    |> Enum.reduce(&add_type/2)
  end

  defp add_type(type, acc) do
    quote do: unquote(type) | unquote(acc)
  end
end
