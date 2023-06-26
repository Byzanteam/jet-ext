defmodule JetExt.Ecto.STI.Changeset do
  @moduledoc """
  Changeset utils for STI.
  """

  @typep field() :: atom()

  @typep errors() :: %{atom() => [Ecto.Changeset.error()]}
  @typep array_errors() :: [errors()]
  @type sti_errors() :: errors() | array_errors()

  @spec validate_change(
          Ecto.Changeset.t(),
          field,
          (field, term() -> errors())
        ) ::
          Ecto.Changeset.t()
        when field: field()
  def validate_change(%Ecto.Changeset{} = changeset, field, validator) do
    Ecto.Changeset.validate_change(
      changeset,
      field,
      fn ^field, value ->
        {cardinality, module} =
          case Map.fetch!(changeset.types, field) do
            {:array, module} -> {:many, module}
            module -> {:one, module}
          end

        Code.ensure_loaded!(module)

        validator = fn value -> validator.(field, value) end

        case {cardinality, do_validate_change(cardinality, value, validator)} do
          {:one, errors} when errors === %{} ->
            []

          {:one, errors} ->
            [
              {field, {"is invalid", [validation: :sti, sti_errors: errors]}}
            ]

          {:many, []} ->
            []

          {:many, errors} ->
            # credo:disable-for-next-line Credo.Check.Refactor.Nesting
            if Enum.all?(errors, &(&1 === %{})) do
              []
            else
              [
                {field, {"is invalid", [validation: :sti, sti_errors: errors]}}
              ]
            end
        end
      end
    )
  end

  defp do_validate_change(:one, value, validator) do
    validator.(value)
  end

  defp do_validate_change(:many, values, validator) do
    Enum.map(values, &do_validate_change(:one, &1, validator))
  end

  @spec collect_errors(Ecto.Changeset.t()) :: errors()
  def collect_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, &Function.identity/1)
  end
end
