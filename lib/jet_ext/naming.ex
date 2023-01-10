defmodule JetExt.Naming do
  @moduledoc false

  @type t() :: module()
  @type token() :: term()
  @type token_modules() :: %{token() => module()}
  @typep using_opts() :: [token_modules: token_modules()]

  @callback tokens() :: [token(), ...]
  @callback modules() :: [module(), ...]
  @callback token_modules() :: token_modules()

  @callback resolve_module(token()) :: {:ok, module()} | :error
  @callback resolve_module!(token()) :: module()

  @callback resolve_token(module()) :: {:ok, token()} | :error
  @callback resolve_token!(module()) :: token()

  @spec __using__(opts :: using_opts()) :: Macro.t()
  defmacro __using__(opts) do
    token_modules =
      opts
      |> Macro.expand(__CALLER__)
      |> Keyword.fetch!(:token_modules)

    quote location: :keep, bind_quoted: [token_modules: token_modules] do
      @token_modules Map.new(token_modules)

      @tokens Map.keys(@token_modules)
      @modules Map.values(@token_modules)

      @behaviour JetExt.Naming

      @impl JetExt.Naming
      def token_modules, do: @token_modules

      @impl JetExt.Naming
      def tokens, do: @tokens

      @impl JetExt.Naming
      def modules, do: @modules

      @impl JetExt.Naming
      def resolve_module(token) when is_binary(token) do
        token
        |> Macro.underscore()
        |> String.to_existing_atom()
        |> resolve_module()
      rescue
        _exception in ArgumentError ->
          :error
      end

      for {token, module} <- @token_modules do
        def resolve_module(unquote(token)), do: {:ok, unquote(module)}
      end

      def resolve_module(_token), do: :error

      @impl JetExt.Naming
      for {token, module} <- @token_modules do
        def resolve_token(unquote(module)), do: {:ok, unquote(token)}
      end

      def resolve_token(_module), do: :error

      @impl JetExt.Naming
      def resolve_module!(token) do
        case resolve_module(token) do
          {:ok, module} ->
            module

          :error ->
            raise ArgumentError, "could not resolve module for token: #{token}"
        end
      end

      @impl JetExt.Naming
      def resolve_token!(module) do
        case resolve_token(module) do
          {:ok, token} ->
            token

          :error ->
            raise ArgumentError, "could not resolve token for module: #{module}"
        end
      end
    end
  end
end
