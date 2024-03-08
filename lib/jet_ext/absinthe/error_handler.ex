if Code.ensure_loaded?(Absinthe) do
  defmodule JetExt.Absinthe.ErrorHandler do
    @moduledoc """
    Absinthe error handlers can handle more data types as an error when works
    with `JetExt.Absinthe.Middleware.HandleError`.
    """

    @doc """
    This is the main callback of an error handler.

    It accepts any type of error and returns a `{:ok, term}` tuple if the error
    can be handled, otherwise it returns `:error`.
    """
    @callback handle(error :: term()) :: {:ok, term()} | :error
  end
end
