defmodule JetExt.Ecto.STI.ParameterizedTest do
  use ExUnit.Case

  alias JetExt.Ecto.STI.Parameterized
  alias JetExt.Ecto.STI.Support.LSP

  @ecto_type {
    :parameterized,
    Parameterized,
    Parameterized.init(intermediate_module: LSP.IntermediateModule)
  }

  describe "cast" do
    test "works" do
      assert {:ok, nil} === Ecto.Type.cast(@ecto_type, nil)

      assert {
               :ok,
               %LSP.Elixir{
                 settings: %LSP.Elixir.Settings{executable_path: "home"}
               }
             } ===
               Ecto.Type.cast(@ecto_type, %{
                 type: :elixir,
                 settings: %{
                   executable_path: "home"
                 }
               })

      assert {
               :ok,
               [
                 %LSP.Elixir{
                   settings: %LSP.Elixir.Settings{executable_path: "home"}
                 },
                 nil
               ]
             } ===
               Ecto.Type.cast({:array, @ecto_type}, [
                 %{
                   type: :elixir,
                   settings: %{
                     executable_path: "home"
                   }
                 },
                 nil
               ])
    end

    test "dose not work" do
      assert {
               :error,
               [
                 validation: :sti,
                 sti_errors: %{type: [{"can't be blank", [validation: :required]}]}
               ]
             } ===
               Ecto.Type.cast(@ecto_type, %{
                 settings: %{
                   executable_path: "home"
                 }
               })

      assert :error ===
               Ecto.Type.cast({:array, @ecto_type}, [
                 %{
                   settings: %{
                     executable_path: "home"
                   }
                 },
                 nil
               ])
    end
  end

  test "dump" do
    elixir_lsp = %LSP.Elixir{
      settings: %LSP.Elixir.Settings{executable_path: "home"}
    }

    assert {
             :ok,
             %{settings: %{executable_path: "home"}, type: "ELIXIR"}
           } === Ecto.Type.dump(@ecto_type, elixir_lsp)

    assert {:ok, nil} === Ecto.Type.dump(@ecto_type, nil)

    assert {:ok, [%{settings: %{executable_path: "home"}, type: "ELIXIR"}, nil]} ===
             Ecto.Type.dump({:array, @ecto_type}, [elixir_lsp, nil])
  end

  test "load" do
    ruby_lsp = %LSP.Ruby{warn_on_meta_programming: true}

    assert {:ok, ruby_lsp} ===
             Ecto.Type.load(@ecto_type, %{"type" => "RUBY", "warn_on_meta_programming" => true})

    assert {:ok, nil} === Ecto.Type.load(@ecto_type, nil)

    assert {:ok, [ruby_lsp, nil]} ===
             Ecto.Type.load({:array, @ecto_type}, [
               %{"type" => "RUBY", "warn_on_meta_programming" => true},
               nil
             ])
  end
end
