defmodule JetExt.Absinthe.OneOf.Middleware.InputModifierTest do
  use ExUnit.Case, async: true

  @moduletag :unit

  alias JetExt.Absinthe.OneOf.TestSchema, as: Schema

  test "works" do
    doc = """
    mutation {
      oneOfTestMutation(input: { foo: { field_a: "a", }}) {
        foo
      }
    }
    """

    assert {:ok, %{data: %{"oneOfTestMutation" => %{"foo" => "field_a"}}}} =
             Absinthe.run(doc, Schema, pipeline_modifier: &pipeline_modifier/2)
  end

  test "works for structs" do
    doc = """
    mutation {
      a: oneOfTestStructMutation(input: { struct: { structA: { a: "a" }}}) {
        struct
      }

      b: oneOfTestStructMutation(input: { struct: { structB: { b: "b" }}}) {
        struct
      }
    }
    """

    assert {:ok, %{data: data}} =
             Absinthe.run(doc, Schema, pipeline_modifier: &pipeline_modifier/2)

    assert get_in(data, ["a", "struct"]) === inspect(%Schema.A{a: "a"})
    assert get_in(data, ["b", "struct"]) === inspect(%Schema.B{b: "b"})
  end

  defp pipeline_modifier(pipeline, _options) do
    Absinthe.Pipeline.insert_after(
      pipeline,
      Absinthe.Phase.Document.Validation.OnlyOneSubscription,
      JetExt.Absinthe.OneOf.Phase
    )
  end
end
