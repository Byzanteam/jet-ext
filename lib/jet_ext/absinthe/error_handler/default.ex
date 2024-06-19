if Code.ensure_loaded?(Absinthe) and Code.ensure_loaded?(Ecto.Changeset) do
  defmodule JetExt.Absinthe.ErrorHandler.Default do
    @moduledoc """
    The default error handler for `JetExt.Absinthe.Middleware.HandleError` that handles ecto
    changeset as an error.

    If the `PolymorphicEmbed` module is loaded, it will use the `traverse_errors` function from it,
    otherwise it will use the `traverse_errors` function from `Ecto.Changeset`.
    """

    @behaviour JetExt.Absinthe.ErrorHandler

    require Logger

    @impl JetExt.Absinthe.ErrorHandler
    def handle(atom) when is_atom(atom), do: {:ok, Atom.to_string(atom)}

    def handle(exception) when is_exception(exception) do
      {:ok, %{message: Exception.message(exception)}}
    end

    def handle(%Ecto.Changeset{} = changeset) do
      changeset
      |> traverse_errors(fn {message, options} ->
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

    if Code.ensure_loaded?(PolymorphicEmbed) do
      defp traverse_errors(changeset, fun), do: PolymorphicEmbed.traverse_errors(changeset, fun)
    else
      defp traverse_errors(changeset, fun), do: Ecto.Changeset.traverse_errors(changeset, fun)
    end
  end
end
