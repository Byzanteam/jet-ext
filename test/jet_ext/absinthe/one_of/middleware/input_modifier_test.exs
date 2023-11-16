defmodule JetExt.Absinthe.OneOf.Middleware.InputModifierTest do
  use ExUnit.Case, async: true

  @moduletag :unit

  alias JetExt.Absinthe.OneOf.TestSchema, as: Schema

  test "works" do
    doc = """
    mutation {
      oneOfTestMutation(input: { foo: { field_a: "a", }}) {
        bar
      }
    }
    """

    assert {:ok, %{data: %{"oneOfTestMutation" => %{"bar" => "field_a"}}}} =
             Absinthe.run(doc, Schema, pipeline_modifier: &pipeline_modifier/2)
  end

  defp pipeline_modifier(pipeline, _options) do
    Absinthe.Pipeline.insert_after(
      pipeline,
      Absinthe.Phase.Document.Validation.OnlyOneSubscription,
      JetExt.Absinthe.OneOf.Phase
    )
  end
end
