defmodule JetExt.Ecto.VarcharTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset

  alias JetExt.Ecto.Varchar

  defmodule MyVarcharSchema do
    use Ecto.Schema

    embedded_schema do
      field :grapheme_field, Varchar, limit: 2

      field :byte_field, Varchar, limit: 3, count: :bytes
    end
  end

  test "count is graphemes" do
    assert match?(
             %Ecto.Changeset{
               valid?: true
             },
             cast(%MyVarcharSchema{}, %{grapheme_field: "中文"}, [:grapheme_field])
           )

    assert match?(
             %Ecto.Changeset{
               valid?: false,
               errors: [
                 grapheme_field:
                   {"is invalid",
                    [
                      type:
                        {:parameterized, {JetExt.Ecto.Varchar, %{count: :graphemes, limit: 2}}},
                      count: 2,
                      validation: :length,
                      kind: :max
                    ]}
               ]
             },
             cast(%MyVarcharSchema{}, %{grapheme_field: "中文长"}, [:grapheme_field])
           )
  end

  test "count is bytes" do
    assert match?(
             %Ecto.Changeset{
               valid?: true
             },
             cast(%MyVarcharSchema{}, %{byte_field: "字"}, [:byte_field])
           )

    assert match?(
             %Ecto.Changeset{
               valid?: false,
               errors: [
                 byte_field:
                   {"is invalid",
                    [
                      type: {:parameterized, {JetExt.Ecto.Varchar, %{count: :bytes, limit: 3}}},
                      count: 3,
                      validation: :length,
                      kind: :max
                    ]}
               ]
             },
             cast(%MyVarcharSchema{}, %{byte_field: "中文"}, [:byte_field])
           )
  end
end
