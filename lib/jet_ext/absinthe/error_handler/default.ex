if Code.ensure_loaded?(Absinthe) and Code.ensure_loaded?(Ecto.Changeset) do
  defmodule JetExt.Absinthe.ErrorHandler.Default do
    @moduledoc """
    The default error handler for `JetExt.Absinthe.Middleware.HandleError` that handles ecto
    changeset as an error.
    """

    @behaviour JetExt.Absinthe.ErrorHandler

    @impl JetExt.Absinthe.ErrorHandler
    def handle(atom) when is_atom(atom), do: {:ok, Atom.to_string(atom)}

    def handle(exception) when is_exception(exception), do: {:ok, Exception.message(exception)}

    def handle(%Ecto.Changeset{} = changeset) do
      changeset
      |> Ecto.Changeset.traverse_errors(fn {message, options} ->
        options
        |> Map.new()
        |> Map.put(:message, message)
      end)
      |> Enum.flat_map(fn {field, errors} ->
        Enum.map(errors, &Map.put(&1, :field, field))
      end)
      |> then(&{:ok, &1})
    end

    def handle(_error), do: :error
  end
end
