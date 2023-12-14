defmodule JetExt.Config.Env do
  @moduledoc """
  This module is used to get environment variables.

  The most common use case is to import this module in config files.

  ### Example

      # runtime.exs
      import Config
      import JetExt.Config.Env

      config :some_app,
        string: fetch_string!("STRING_ENV"),
        integer: fetch_integer!("INTEGER_ENV")
  """

  @type options() :: [hint: String.t(), default: any()]

  @doc """
  Fetches an environment variable and returns it as a string.

  Options:
  - default: the default value to return if the environment variable is missing
  - hint: a hint to be used in the error message,
  it can contain %{name} which will be replaced by the environment variable name
  """
  @spec fetch_string!(name :: String.t(), options()) :: String.t()
  def fetch_string!(name, options \\ []) when is_binary(name) and is_list(options) do
    case System.fetch_env(name) do
      {:ok, value} ->
        value

      :error ->
        fallback_or_raise!(name, options, "environment variable %{name} is missing")
    end
  end

  @doc """
  Fetches an environment variable and parses it to an integer.

  Options:
  - default: the default value to return if the environment variable is missing
  - hint: a hint to be used in the error message,
  it can contain %{name} which will be replaced by the environment variable name
  """
  @spec fetch_integer!(name :: String.t(), options()) :: integer()
  def fetch_integer!(name, options \\ []) when is_binary(name) and is_list(options) do
    with {:value, value} <- fetch_or_fallback_env(name, options),
         {integer, ""} <- Integer.parse(value) do
      integer
    else
      {:fallback, value} ->
        value

      _otherwise ->
        fallback_or_raise!(
          name,
          Keyword.drop(options, [:default]),
          "environment variable %{name} is missing or it cannot be parsed to integer"
        )
    end
  end

  @spec fetch_or_fallback_env(String.t(), options()) ::
          {:value, any()} | {:fallback, any()} | :error
  defp fetch_or_fallback_env(name, options) do
    case System.fetch_env(name) do
      {:ok, value} ->
        {:value, value}

      :error ->
        with {:ok, value} <- Keyword.fetch(options, :default) do
          {:fallback, value}
        end
    end
  end

  defp fallback_or_raise!(name, options, hint) do
    case Keyword.fetch(options, :default) do
      {:ok, default} -> default
      :error -> raise interpolate_hint(Keyword.get(options, :hint, hint), name)
    end
  end

  defp interpolate_hint(hint, name) do
    String.replace(hint, "%{name}", name)
  end

  @falsey_values ["false", "0", nil]
  @doc """
  Casts an environment variable to a boolean.

  Any string except `"false"` and `"0"` will be cast to `true`.
  Here are some truty values: `"true"`, `"1"`, `"yes"`, `"on"`.
  """
  @spec cast_boolean(name :: String.t()) :: boolean()
  def cast_boolean(name) do
    case System.get_env(name) do
      value when value in @falsey_values -> false
      _otherwise -> true
    end
  end
end
