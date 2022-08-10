defmodule JetExt.Ecto.STI.ChangesetTest do
  use ExUnit.Case

  import JetExt.Ecto.STI.Changeset

  alias JetExt.Ecto.STI.Support.LSP

  @moduletag :unit

  defmodule MyEditor do
    use Ecto.Schema

    @primary_key false

    embedded_schema do
      field :name, :string

      field :lsp, LSP
      field :lsps, {:array, LSP}
    end
  end

  describe "validate_change/3" do
    test "works" do
      changeset =
        Ecto.Changeset.cast(
          %MyEditor{},
          %{
            lsp: %{type: :ruby, warn_on_meta_programming: true},
            lsps: [
              %{type: :ruby, warn_on_meta_programming: true},
              %{type: :elixir, settings: %{executable_path: "/foo/bar"}}
            ]
          },
          [:lsp, :lsps]
        )

      assert match?(
               %Ecto.Changeset{
                 valid?: true
               },
               changeset
               |> validate_change(:lsp, &validate/2)
               |> validate_change(:lsps, &validate/2)
             )
    end

    test "works with invalid params" do
      changeset =
        Ecto.Changeset.cast(
          %MyEditor{},
          %{
            lsp: %{type: :ruby, warn_on_meta_programming: false},
            lsps: [
              %{type: :ruby, warn_on_meta_programming: false},
              %{type: :ruby, warn_on_meta_programming: true},
              %{type: :elixir, settings: %{executable_path: "foo/bar"}}
            ]
          },
          [:lsp, :lsps]
        )

      assert match?(
               %Ecto.Changeset{
                 valid?: false,
                 errors: [
                   lsp:
                     {"is invalid",
                      [
                        validation: :sti,
                        sti_errors: %{
                          warn_on_meta_programming: [
                            {"is invalid", [validation: :inclusion, enum: [true]]}
                          ]
                        }
                      ]}
                 ]
               },
               validate_change(changeset, :lsp, &validate/2)
             )

      assert match?(
               %Ecto.Changeset{
                 valid?: false,
                 errors: [
                   lsps:
                     {"is invalid",
                      [
                        validation: :sti,
                        sti_errors: [
                          %{
                            warn_on_meta_programming: [
                              {"is invalid", [validation: :inclusion, enum: [true]]}
                            ]
                          },
                          %{},
                          %{
                            settings: %{
                              executable_path: [{"has invalid format", [validation: :format]}]
                            }
                          }
                        ]
                      ]}
                 ]
               },
               validate_change(changeset, :lsps, &validate/2)
             )
    end
  end

  describe "collect_errors" do
    test "works" do
      changeset = LSP.Ruby.changeset(%{})

      assert collect_errors(changeset) === %{
               warn_on_meta_programming: [{"can't be blank", [validation: :required]}]
             }

      changeset = LSP.Elixir.changeset(%{settings: %{}})

      assert collect_errors(changeset) === %{
               settings: %{executable_path: [{"can't be blank", [validation: :required]}]}
             }
    end
  end

  defp validate(_field, value) when is_struct(value, LSP.Ruby) do
    %LSP.Ruby{}
    |> Ecto.Changeset.cast(Ecto.embedded_dump(value, :json), [:warn_on_meta_programming])
    |> Ecto.Changeset.validate_inclusion(:warn_on_meta_programming, [true])
    |> collect_errors()
  end

  defp validate(_field, value) when is_struct(value, LSP.Elixir) do
    %LSP.Elixir{}
    |> Ecto.Changeset.cast(Ecto.embedded_dump(value, :json), [])
    |> Ecto.Changeset.cast_embed(:settings,
      with: fn settings, params ->
        settings
        |> Ecto.Changeset.cast(params, [:executable_path])
        |> Ecto.Changeset.validate_format(:executable_path, ~r/^\//)
      end
    )
    |> collect_errors()
  end
end
