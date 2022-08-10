defmodule JetExt.Ecto.STI.BuilderTest do
  use ExUnit.Case, async: true

  alias JetExt.Ecto.STI.Support.LSP

  @moduletag :unit

  describe "cast" do
    test "works on valid data" do
      assert LSP.cast(%{
               type: :elixir,
               settings: %{
                 executable_path: "home"
               }
             }) ===
               {:ok,
                %LSP.Elixir{
                  settings: %LSP.Elixir.Settings{executable_path: "home"}
                }}

      assert LSP.cast(%{
               type: :ruby,
               warn_on_meta_programming: true,
               useless_field: "invalid"
             }) ===
               {:ok, %LSP.Ruby{warn_on_meta_programming: true}}
    end

    test "invalid type" do
      assert LSP.cast(%{
               warn_on_meta_programming: true,
               useless_field: "invalid"
             }) ===
               {:error,
                [
                  validation: :sti,
                  sti_errors: %{
                    type: [{"can't be blank", [validation: :required]}]
                  }
                ]}

      assert LSP.cast(%{
               type: :invalid,
               warn_on_meta_programming: true,
               useless_field: "invalid"
             }) ===
               {:error,
                [
                  validation: :sti,
                  sti_errors: %{
                    type: [{"is invalid", [validation: :inclusion, enum: [:elixir, :ruby]]}]
                  }
                ]}
    end

    test "invalid fields" do
      assert LSP.cast(%{
               type: :ruby,
               warn_on_meta_programming: 1
             }) ===
               {:error,
                [
                  validation: :sti,
                  sti_errors: %{
                    warn_on_meta_programming: [
                      {"is invalid", [type: :boolean, validation: :cast]}
                    ]
                  }
                ]}

      assert LSP.cast(%{
               type: :elixir
             }) ===
               {:error,
                [
                  validation: :sti,
                  sti_errors: %{settings: [{"can't be blank", [validation: :required]}]}
                ]}

      assert LSP.cast(%{
               type: :elixir,
               settings: %{}
             }) ===
               {:error,
                [
                  validation: :sti,
                  sti_errors: %{
                    settings: %{executable_path: [{"can't be blank", [validation: :required]}]}
                  }
                ]}

      assert LSP.cast(%{
               type: :elixir,
               settings: %{executable_path: 1}
             }) ===
               {:error,
                [
                  validation: :sti,
                  sti_errors: %{
                    settings: %{
                      executable_path: [{"is invalid", [type: :string, validation: :cast]}]
                    }
                  }
                ]}
    end
  end

  describe "dump" do
    test "works" do
      {:ok, lsp} = LSP.cast(%{type: :elixir, settings: %{executable_path: "home"}})

      assert LSP.dump(lsp) === {:ok, %{type: "ELIXIR", settings: %{executable_path: "home"}}}
    end
  end

  describe "load" do
    test "works" do
      assert LSP.load(%{"type" => "RUBY", "warn_on_meta_programming" => true}) ===
               {:ok, %LSP.Ruby{warn_on_meta_programming: true}}
    end
  end
end
