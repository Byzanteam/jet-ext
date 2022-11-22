defmodule JetExt.Ecto.STI.Support.LSP.Elixir do
  @moduledoc false
  use Ecto.Schema

  @primary_key false

  defmodule Settings do
    @moduledoc false
    use Ecto.Schema

    @primary_key false

    embedded_schema do
      field :executable_path, :string
    end

    @spec changeset(struct(), map()) :: Ecto.Changeset.t()
    def changeset(schema, params) do
      schema
      |> Ecto.Changeset.cast(params, [:executable_path])
      |> Ecto.Changeset.validate_required([:executable_path])
    end
  end

  embedded_schema do
    embeds_one :settings, Settings
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(params, [])
    |> Ecto.Changeset.cast_embed(:settings, required: true)
  end
end

defmodule JetExt.Ecto.STI.Support.LSP.Ruby do
  @moduledoc false
  use Ecto.Schema

  @primary_key false

  embedded_schema do
    field :warn_on_meta_programming, :boolean
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(params, [:warn_on_meta_programming])
    |> Ecto.Changeset.validate_required([:warn_on_meta_programming])
  end
end

defmodule JetExt.Ecto.STI.Support.LSP.IntermediateModule do
  @moduledoc false

  @behaviour JetExt.Ecto.STI.IntermediateModule

  alias JetExt.Ecto.STI.Support.LSP.Elixir, as: LSPElixir
  alias JetExt.Ecto.STI.Support.LSP.Ruby, as: LSPRuby

  @impl JetExt.Ecto.STI.IntermediateModule
  def cast(%{type: :elixir} = data) do
    {:ok, LSPElixir.changeset(data)}
  end

  def cast(%{type: :ruby} = data) do
    {:ok, LSPRuby.changeset(data)}
  end

  def cast(data) do
    case Map.fetch(data, :type) do
      {:ok, _type} ->
        {:error, {:unexpected_type, {:type, [:elixir, :ruby]}}}

      :error ->
        {:error, {:type_absence, :type}}
    end
  end

  @impl JetExt.Ecto.STI.IntermediateModule
  def dump(%LSPElixir{} = data) do
    data
    |> Ecto.embedded_dump(:json)
    |> Map.merge(%{type: "ELIXIR"})
    |> then(&{:ok, &1})
  end

  def dump(%LSPRuby{} = data) do
    data
    |> Ecto.embedded_dump(:json)
    |> Map.merge(%{type: "RUBY"})
    |> then(&{:ok, &1})
  end

  def dump(_data), do: :error

  @impl JetExt.Ecto.STI.IntermediateModule
  def load(%{"type" => "ELIXIR"} = data) do
    data
    |> LSPElixir.changeset()
    |> Ecto.Changeset.apply_changes()
    |> then(&{:ok, &1})
  end

  def load(%{"type" => "RUBY"} = data) do
    data
    |> LSPRuby.changeset()
    |> Ecto.Changeset.apply_changes()
    |> then(&{:ok, &1})
  end

  def load(_data), do: :error
end

defmodule JetExt.Ecto.STI.Support.LSP do
  @moduledoc false

  use JetExt.Ecto.STI.Builder,
    intermediate_module: JetExt.Ecto.STI.Support.LSP.IntermediateModule
end
