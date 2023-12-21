defmodule JetExt.Absinthe.Types.Scalar.ObjectJSON.TestSchema do
  @moduledoc false

  use Absinthe.Schema

  import_types JetExt.Absinthe.Types.Scalar.ObjectJSON

  query do
    field :foo, :object_json
  end
end
