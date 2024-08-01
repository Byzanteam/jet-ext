import Config

config :jet_ext, ecto_repos: [JetExt.Repo]

config :jet_ext, JetExt.Repo,
  migration_foreign_key: [type: :binary_id],
  migration_primary_key: [type: :binary_id],
  migration_timestamps: [type: :utc_datetime_usec]

import_config "#{config_env()}.exs"
