import Config

config :jet_ext, JetExt.Repo,
  hostname: "localhost",
  database: "jet_ext_test",
  username: "postgres",
  password: "postgres",
  pool: Ecto.Adapters.SQL.Sandbox
