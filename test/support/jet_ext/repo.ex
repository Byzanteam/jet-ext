defmodule JetExt.Repo do
  @moduledoc false

  use Ecto.Repo, otp_app: :jet_ext, adapter: Ecto.Adapters.Postgres

  @spec execute_ddl(command :: term()) :: Postgrex.Result.t()
  def execute_ddl(command) do
    command
    |> Ecto.Adapters.Postgres.Connection.execute_ddl()
    |> Enum.map(&IO.iodata_to_binary/1)
    |> query()
  end
end
