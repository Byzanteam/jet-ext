[
  inputs: [
    "{mix,.credo,.formatter}.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  import_deps: [
    :credo,
    :ecto
  ]
]
