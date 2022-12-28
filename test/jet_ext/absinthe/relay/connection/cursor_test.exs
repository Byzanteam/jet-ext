defmodule JetExt.Absinthe.Relay.Connection.CursorTest do
  use ExUnit.Case, async: true

  alias JetExt.Absinthe.Relay.Connection.Config
  alias JetExt.Absinthe.Relay.Connection.Cursor

  test "works" do
    config = Config.new(cursor_fields: [name: :asc, phone: :asc])

    name = "Alice"
    phone = 13_912_344_321
    record = %{name: name, phone: phone, balance: 0.00}

    cursor = Cursor.encode_record(record, config)

    assert is_binary(cursor)
    assert {:ok, %{name: ^name, phone: ^phone}} = Cursor.decode(cursor)
  end
end
