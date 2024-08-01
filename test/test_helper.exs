{:ok, _apps} = Application.ensure_all_started(:postgrex)

{:ok, _pid} = JetExt.Repo.start_link()

Ecto.Adapters.SQL.Sandbox.mode(JetExt.Repo, :manual)

Mimic.copy(System)

ExUnit.start(capture_log: true)
