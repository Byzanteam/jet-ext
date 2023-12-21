defmodule JetExt.Absinthe.Types.Scalar.ObjectJSONTest do
  use ExUnit.Case, async: true

  alias JetExt.Absinthe.Types.Scalar.ObjectJSON.TestSchema

  @data %{
    string_a: "foo",
    number: Decimal.new("1.1"),
    boolean: true,
    null: nil,
    now: NaiveDateTime.new!(2000, 1, 1, 0, 0, 0),
    recursive: [
      %{
        string_b: "foo"
      },
      Decimal.new("1.2"),
      [
        NaiveDateTime.new!(2001, 1, 1, 0, 0, 0)
      ]
    ]
  }

  describe "serialize" do
    test "works" do
      result = serialize(@data)

      assert Jason.decode!(result) === %{
               "string_a" => "foo",
               "number" => 1.1,
               "boolean" => true,
               "null" => nil,
               "now" => "2000-01-01T00:00:00",
               "recursive" => [
                 %{"string_b" => "foo"},
                 1.2,
                 ["2001-01-01T00:00:00"]
               ]
             }
    end
  end

  describe "parse" do
    test "works" do
      assert @data |> serialize() |> parse() ===
               {:ok,
                %{
                  "string_a" => "foo",
                  "number" => 1.1,
                  "boolean" => true,
                  "null" => nil,
                  "now" => "2000-01-01T00:00:00",
                  "recursive" => [
                    %{"string_b" => "foo"},
                    1.2,
                    ["2001-01-01T00:00:00"]
                  ]
                }}
    end
  end

  defp serialize(value) do
    :object_json
    |> TestSchema.__absinthe_type__()
    |> Absinthe.Type.Scalar.serialize(value)
  end

  defp parse(value) do
    :object_json
    |> TestSchema.__absinthe_type__()
    |> Absinthe.Type.Scalar.parse(%Absinthe.Blueprint.Input.String{value: value})
  end
end
