defmodule JetExt.Ecto.Sti.IntermediationTest do
  use ExUnit.Case, async: true

  alias JetExt.Ecto.STI.Intermediation

  defmodule FieldType do
    use JetExt.Ecto.Enum, [:boolean, :datetime, :numeric]
  end

  defmodule BooleanField do
    defstruct name: "boolean_field"

    @spec changeset(struct(), map()) :: struct()
    def changeset(%__MODULE__{}, params) do
      %__MODULE__{name: params.name}
    end
  end

  defmodule NumericField do
    defstruct name: "numeric_field"

    @spec changeset(struct(), map()) :: struct()
    def changeset(%__MODULE__{}, params) do
      %__MODULE__{name: params.name}
    end
  end

  defmodule SingleNaming do
    use JetExt.Naming,
      token_modules: [
        boolean: BooleanField,
        numeric: NumericField
      ]
  end

  defmodule OperatorType do
    use JetExt.Ecto.Enum, [:is_nil, :is_empty]
  end

  defmodule BooleanIsNil do
    defstruct name: "foo"

    @spec changeset(struct(), map()) :: struct()
    def changeset(%__MODULE__{}, params) do
      %__MODULE__{name: params.name}
    end
  end

  defmodule DatetimeIsEmpty do
    defstruct name: "bar"

    @spec changeset(struct(), map()) :: struct()
    def changeset(%__MODULE__{}, params) do
      %__MODULE__{name: params.name}
    end
  end

  defmodule MultipleNaming do
    use JetExt.Naming,
      token_modules: [
        {{:boolean, :is_nil}, BooleanIsNil},
        {{:datetime, :is_empty}, DatetimeIsEmpty}
      ]
  end

  setup :setup_type_fields

  test "cast/3", ctx do
    %{
      test: test,
      multiple_type_fields: multiple_type_fields,
      single_type_fields: single_type_fields
    } = ctx

    assert {:ok, %BooleanField{name: ^test}} =
             Intermediation.cast(
               SingleNaming,
               %{field: "boolean", name: test},
               single_type_fields
             )

    assert {:error, {:type_absence, [:field]}} =
             Intermediation.cast(SingleNaming, %{name: test}, single_type_fields)

    assert {:error, {:unexpected_type, [:field]}} =
             Intermediation.cast(SingleNaming, %{field: "single", name: test}, single_type_fields)

    assert {:ok, %BooleanIsNil{name: ^test}} =
             Intermediation.cast(
               MultipleNaming,
               %{field: "boolean", operator: "is_nil", name: test},
               multiple_type_fields
             )

    assert {:ok, %DatetimeIsEmpty{name: ^test}} =
             Intermediation.cast(
               MultipleNaming,
               %{field: "datetime", operator: "is_empty", name: test},
               multiple_type_fields
             )

    assert :error =
             Intermediation.cast(
               MultipleNaming,
               %{field: "numeric", operator: "is_nil", name: test},
               multiple_type_fields
             )
  end

  test "fetch_token/3", ctx do
    %{
      multiple_type_fields: multiple_type_fields,
      single_type_fields: single_type_fields,
      test: test
    } = ctx

    assert {:ok, :boolean} =
             Intermediation.fetch_token(SingleNaming, %{field: "boolean"}, single_type_fields)

    assert {:error, {:type_absence, [:field]}} =
             Intermediation.fetch_token(SingleNaming, %{name: test}, single_type_fields)

    assert {:error, {:unexpected_type, [:field]}} =
             Intermediation.fetch_token(SingleNaming, %{field: "single"}, single_type_fields)

    assert {:ok, {:boolean, :is_nil}} =
             Intermediation.fetch_token(
               MultipleNaming,
               %{field: "boolean", operator: :is_nil},
               multiple_type_fields
             )

    assert {:ok, {:datetime, :is_empty}} =
             Intermediation.fetch_token(
               MultipleNaming,
               %{field: "datetime", operator: "is_empty"},
               multiple_type_fields
             )

    assert :error =
             Intermediation.fetch_token(
               MultipleNaming,
               %{field: "numeric", operator: "is_empty"},
               multiple_type_fields
             )

    assert {:error, {:type_absence, [:field, :operator]}} =
             Intermediation.fetch_token(MultipleNaming, %{field: "numeric"}, multiple_type_fields)
  end

  test "dump_token/3", ctx do
    %{multiple_type_fields: multiple_type_fields, single_type_fields: single_type_fields} = ctx

    assert %{field: "BOOLEAN"} =
             Intermediation.dump_token(SingleNaming, BooleanField, single_type_fields)

    assert %{field: "BOOLEAN", operator: "IS_NIL"} =
             Intermediation.dump_token(MultipleNaming, BooleanIsNil, multiple_type_fields)

    assert %{field: "DATETIME", operator: "IS_EMPTY"} =
             Intermediation.dump_token(MultipleNaming, DatetimeIsEmpty, multiple_type_fields)
  end

  defp setup_type_fields(%{}) do
    [
      multiple_type_fields: [field: FieldType, operator: OperatorType],
      single_type_fields: [field: FieldType]
    ]
  end
end
