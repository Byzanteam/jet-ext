defmodule JetExt.Ecto.EnumTest do
  use ExUnit.Case, async: true

  defmodule EnumType do
    use JetExt.Ecto.Enum, [:foo, :bar]
  end

  test "cast/1" do
    assert EnumType.cast("foo") === {:ok, :foo}
    assert EnumType.cast("FOO") === {:ok, :foo}
    assert EnumType.cast(:foo) === {:ok, :foo}

    assert EnumType.cast(:baz) === :error
  end

  test "load/1" do
    assert EnumType.load("foo") === {:ok, :foo}
    assert EnumType.load("FOO") === {:ok, :foo}

    assert EnumType.load("baz") === :error
  end

  test "dump/1" do
    assert EnumType.dump(:foo) === {:ok, "FOO"}

    assert EnumType.dump(:baz) === :error
  end
end
