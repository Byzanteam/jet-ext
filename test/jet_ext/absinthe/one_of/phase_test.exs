defmodule JetExt.Absinthe.OneOf.PhaseTest do
  use ExUnit.Case, async: true

  @moduletag :unit

  alias JetExt.Absinthe.OneOf.TestSchema, as: Schema

  test "works" do
    invalid_doc = """
    mutation {
      oneOfTestMutation(input: { foo: {
        field_a: "a",
        field_b: "b"
      }}) {
        foo
      }
    }
    """

    assert {:ok, %{errors: [%{message: message}]}} =
             Absinthe.run(invalid_doc, Schema, pipeline_modifier: &pipeline_modifier/2)

    assert message =~ "OneOf Object"

    assert {:ok, %{errors: [%{message: message}]}} = Absinthe.run(invalid_doc, Schema)

    assert message =~ "invalid arguments"
  end

  defp pipeline_modifier(pipeline, _options) do
    Absinthe.Pipeline.insert_after(
      pipeline,
      Absinthe.Phase.Document.Validation.OnlyOneSubscription,
      JetExt.Absinthe.OneOf.Phase
    )
  end
end
