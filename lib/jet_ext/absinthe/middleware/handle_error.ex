if Code.ensure_loaded?(Absinthe) do
  defmodule JetExt.Absinthe.Middleware.HandleError do
    @moduledoc """
    Absinthe Middleware to support more types of error.

    The operating logic of error handlers is in the form of fallback,
    and each error is handled by at most one handler.

    It can be configured with:

      config :jext_ext, Absinthe,
        error_handlers: [JetExt.Absinthe.ErrorHandler.Default, MyHanler]
    """

    @behaviour Absinthe.Middleware

    @handlers Application.compile_env(
                :jet_ext,
                [Absinthe, :error_handlers],
                [JetExt.Absinthe.ErrorHandler.Default]
              )

    @impl Absinthe.Middleware
    def call(%Absinthe.Resolution{} = resolution, _opts) do
      Absinthe.Resolution.put_result(
        resolution,
        {:error, Enum.flat_map(resolution.errors, &transform/1)}
      )
    end

    defp transform(error) do
      @handlers
      |> Enum.reduce_while(error, fn handler, default ->
        case handler.handle(default) do
          {:ok, error} -> {:halt, error}
          :error -> {:cont, default}
        end
      end)
      |> List.wrap()
    end
  end
end
