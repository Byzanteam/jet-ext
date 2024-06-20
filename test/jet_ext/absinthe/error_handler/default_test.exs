defmodule JetExt.Absinthe.ErrorHandler.DefaultTest do
  use ExUnit.Case, async: true

  alias JetExt.Absinthe.ErrorHandler.Default, as: DefaultHandler

  defmodule CustomError do
    @type t() :: %__MODULE__{
            message: String.t()
          }

    defexception [:message]
  end

  defmodule CustomSchema do
    use Ecto.Schema

    alias JetExt.Absinthe.ErrorHandler.DefaultTest.Foo

    @primary_key false

    embedded_schema do
      field :name, :string
      embeds_one :foo, Foo, on_replace: :update
    end

    def changeset(schema \\ %__MODULE__{}, params) do
      schema
      |> Ecto.Changeset.cast(params, [:name])
      |> Ecto.Changeset.cast_embed(:foo, required: true)
      |> Ecto.Changeset.validate_required(:name)
    end
  end

  defmodule CustomPolymorphicEmbedSchema do
    use Ecto.Schema

    import PolymorphicEmbed

    alias JetExt.Absinthe.ErrorHandler.DefaultTest.Foo

    @primary_key false

    embedded_schema do
      field :name, :string

      polymorphic_embeds_one(:amount,
        types: [
          foo: Foo
        ],
        on_type_not_found: :changeset_error,
        on_replace: :update
      )
    end

    @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
    def changeset(schema \\ %__MODULE__{}, params) do
      schema
      |> Ecto.Changeset.cast(params, [:name])
      |> cast_polymorphic_embed(:amount, required: true)
      |> Ecto.Changeset.validate_required(:name)
    end
  end

  defmodule Foo do
    use Ecto.Schema

    @primary_key false

    embedded_schema do
      field :count, :integer
    end

    @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
    def changeset(schema \\ %__MODULE__{}, params) do
      schema
      |> Ecto.Changeset.cast(params, [:count])
      |> Ecto.Changeset.validate_number(:count, greater_than: 1)
    end
  end

  describe "handle/1" do
    test "handle with atom" do
      assert {:ok, "already_exists"} === DefaultHandler.handle(:already_exists)
    end

    test "handle with exception" do
      exception = %CustomError{message: "custom error"}
      assert {:ok, %{message: "custom error"}} === DefaultHandler.handle(exception)
    end

    test "handle with ecto changeset" do
      assert {:ok, %{message: "Validation failed", details: details}} =
               %{"foo" => %{"count" => 0}}
               |> CustomSchema.changeset()
               |> DefaultHandler.handle()

      assert match?(
               %{
                 name: [%{message: _name_message, validation: :required}],
                 foo: %{
                   count: [
                     %{
                       message: _count_message,
                       validation: :number
                     }
                   ]
                 }
               },
               details
             )
    end

    test "handle with ecto changeset with polymorphic embed" do
      assert {:ok, %{message: "Validation failed", details: details}} =
               %{"amount" => %{"__type__" => "foo", "count" => 0}}
               |> CustomPolymorphicEmbedSchema.changeset()
               |> DefaultHandler.handle()

      assert match?(
               %{
                 name: [%{message: _name_message, validation: :required}],
                 amount: %{
                   count: [
                     %{
                       message: _count_message,
                       validation: :number
                     }
                   ]
                 }
               },
               details
             )
    end
  end
end
