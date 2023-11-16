defmodule JetExt.Ecto.STI.Logger do
  @moduledoc false

  @spec log_cast_error(Ecto.Type.t(), term(), Inspect.t()) :: :ok
  def log_cast_error(type, data, reason) do
    log("""
    Cannot cast
    #{inspect(data)} to #{inspect(type)}
    due to #{inspect(reason)}
    """)
  end

  @spec log_dump_error(Ecto.Type.t(), term()) :: :ok
  def log_dump_error(type, data) do
    log("""
    Cannot cast
    #{inspect(data)} of type #{inspect(type)}
    """)
  end

  @spec log_load_error(Ecto.Type.t(), term()) :: :ok
  def log_load_error(type, data) do
    log("""
    Cannot load
    #{inspect(data)} of type #{inspect(type)}
    """)
  end

  defp log(message) do
    require Logger

    Logger.warning(fn -> message end)
  end
end
