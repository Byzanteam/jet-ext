defmodule JetExt.Ecto.EnumTest do
  use ExUnit.Case, async: true

  defmodule EnumType do
    use JetExt.Ecto.Enum, [:foo, :bar]
  end

  defmodule ParameterizedSchema do
    use Ecto.Schema

    embedded_schema do
      field :type, JetExt.Ecto.Enum, values: [:foo, :bar]
    end
  end

  describe "module type" do
    test "cast/1" do
      assert EnumType.cast("foo") === {:ok, :foo}
      assert EnumType.cast("FOO") === {:ok, :foo}
      assert EnumType.cast(:foo) === {:ok, :foo}

      assert EnumType.cast(:baz) === :error
    end

    test "dump/1" do
      assert EnumType.dump(:foo) === {:ok, "FOO"}

      assert EnumType.dump(:baz) === :error
    end

    test "load/1" do
      assert EnumType.load("foo") === {:ok, :foo}
      assert EnumType.load("FOO") === {:ok, :foo}

      assert EnumType.load("baz") === :error
    end
  end

  describe "parameterized type" do
    setup do
      [type: Ecto.ParameterizedType.init(JetExt.Ecto.Enum, values: [:foo, :bar, :baz])]
    end

    test "cast/2", %{type: type} do
      assert {:ok, :foo} === Ecto.Type.cast(type, :foo)
      assert {:ok, :bar} === Ecto.Type.cast(type, "bar")
      assert {:ok, :baz} === Ecto.Type.cast(type, "BAZ")
    end

    test "dump/2", %{type: type} do
      assert {:ok, "FOO"} === Ecto.Type.dump(type, :foo)
      assert :error === Ecto.Type.dump(type, :baa)
    end

    test "load/2", %{type: type} do
      assert {:ok, :foo} = Ecto.Type.load(type, "FOO")
      assert :error = Ecto.Type.load(type, "foo")
    end

    test "dump_values/2" do
      Enum.sort(JetExt.Ecto.Enum.dump_values(ParameterizedSchema, :type))
    end

    test "mappings/2" do
      assert [bar: "bar", foo: "foo"] ===
               Enum.sort(JetExt.Ecto.Enum.mappings(ParameterizedSchema, :type))
    end

    test "values/2" do
      assert [:bar, :foo] === Enum.sort(JetExt.Ecto.Enum.values(ParameterizedSchema, :type))
    end
  end
end
