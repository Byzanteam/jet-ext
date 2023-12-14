defmodule JetExt.Config.EnvTest do
  use ExUnit.Case, async: true
  use Mimic

  import JetExt.Config.Env

  describe "fetch_string!/2" do
    setup do
      stub(
        System,
        :fetch_env,
        fetch_env_stubbed(%{
          "ENV_VAR" => "env_var"
        })
      )

      :ok
    end

    test "fetch env var" do
      assert fetch_string!("ENV_VAR") === "env_var"

      assert_raise(RuntimeError, ~r/NON_EXISTING_ENV_VAR/, fn ->
        fetch_string!("NON_EXISTING_ENV_VAR")
      end)
    end

    test "with default" do
      assert fetch_string!("NON_EXISTING_ENV_VAR", default: "default_env_var") ===
               "default_env_var"
    end

    test "with hint" do
      assert_raise(RuntimeError, "hint", fn ->
        fetch_string!("NON_EXISTING_ENV_VAR", hint: "hint")
      end)

      assert_raise(RuntimeError, "NON_EXISTING_ENV_VAR", fn ->
        fetch_string!("NON_EXISTING_ENV_VAR", hint: "%{name}")
      end)
    end
  end

  describe "fetch_integer!/2" do
    setup do
      stub(
        System,
        :fetch_env,
        fetch_env_stubbed(%{
          "INTEGER" => "100",
          "FLOAT" => "100.1",
          "STRING" => "string"
        })
      )

      :ok
    end

    test "fetch env var" do
      assert fetch_integer!("INTEGER") === 100

      assert_raise(RuntimeError, ~r/FLOAT/, fn ->
        fetch_integer!("FLOAT")
      end)

      assert_raise(RuntimeError, ~r/STRING/, fn ->
        fetch_integer!("STRING")
      end)

      assert_raise(RuntimeError, ~r/NON_EXISTING_ENV_VAR/, fn ->
        fetch_integer!("NON_EXISTING_ENV_VAR")
      end)
    end

    test "with default" do
      assert fetch_integer!("NON_EXISTING_ENV_VAR", default: 200) === 200

      assert_raise(RuntimeError, ~r/FLOAT/, fn ->
        fetch_integer!("FLOAT", default: 200)
      end)

      assert_raise(RuntimeError, ~r/STRING/, fn ->
        fetch_integer!("STRING", default: 200)
      end)
    end

    test "with hint" do
      assert_raise(RuntimeError, "hint", fn ->
        fetch_integer!("NON_EXISTING_ENV_VAR", hint: "hint")
      end)

      assert_raise(RuntimeError, "NON_EXISTING_ENV_VAR", fn ->
        fetch_integer!("NON_EXISTING_ENV_VAR", hint: "%{name}")
      end)
    end
  end

  describe "cast_boolean/1" do
    setup do
      stub(
        System,
        :get_env,
        get_env_stubbed(%{
          "TRUE" => "true",
          "FALSE" => "false",
          "0" => "0",
          "STRING" => "string"
        })
      )

      :ok
    end

    test "works" do
      assert cast_boolean("TRUE") === true
      assert cast_boolean("FALSE") === false
      assert cast_boolean("0") === false
      assert cast_boolean("NON_EXISTING_ENV_VAR") === false
      assert cast_boolean("STRING") === true
    end
  end

  defp fetch_env_stubbed(envs) do
    envs = Map.new(envs)

    fn name ->
      Map.fetch(envs, name)
    end
  end

  defp get_env_stubbed(envs) do
    envs = Map.new(envs)

    fn name ->
      Map.get(envs, name)
    end
  end
end
