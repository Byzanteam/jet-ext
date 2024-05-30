defmodule JetExt.Absinthe.OneOf do
  @moduledoc """
  The homemade `one_of` directive for Absinthe.

  ## 使用方法
  1. 参考 `JetExt.Absinthe.OneOf.Phase` 的文档，将 phase 加入到 absinthe 的 phases 中
  2. 参考 `JetExt.Absinthe.OneOf.SchemaProtoType` 的文档，在你的 absinthe schema 引入 `:one_of` directive
  3. 参考 `JetExt.Absinthe.OneOf.Middleware.InputModifier` 的文档，用 `:one_of` 来定义你的 input_object
  4. `JetExt.Absinthe.OneOf.Helpers` 目前提供了一个 `fold_key_to_field/3`，一个使用案例参考 3 中的例子
  """
end
