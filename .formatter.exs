[
  inputs: [
    "{mix,.credo,.formatter}.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  import_deps: [
    :absinthe,
    :credo,
    :ecto
  ]
]
