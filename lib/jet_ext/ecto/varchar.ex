defmodule JetExt.Ecto.Varchar do
  @moduledoc """
  An Ecto type for PostgreSQL varchar with limit.

  ## Options

    * `:limit` - the length must be less than or equal to this value (default is 255)
    * `:count` - what length to count for string, `:graphemes` (default) or `:bytes`

  ## Example

  ```
  field :name, JetExt.Ecto.Varchar, limit: 255

  field :name, JetExt.Ecto.Varchar, limit: 255, count: :bytes
  ```
  """

  use Ecto.ParameterizedType

  @impl Ecto.ParameterizedType
  def type(_params), do: :string

  @impl Ecto.ParameterizedType
  def init(opts) do
    validate_opts(opts)
  end

  @default_limit 255
  @default_count :graphemes
  @counts [:graphemes, :bytes]

  defp validate_opts(opts) do
    limit = Keyword.get(opts, :limit, @default_limit)

    if limit < 0 do
      raise ArgumentError, "limit must be positive"
    end

    count = Keyword.get(opts, :count, @default_count)

    if count not in @counts do
      raise ArgumentError, "count must be in #{inspect(@counts)}"
    end

    %{
      limit: limit,
      count: count
    }
  end

  @impl Ecto.ParameterizedType
  def cast(data, opts) do
    with(
      {:ok, str} when is_binary(str) <- Ecto.Type.cast(:string, data),
      true <- valid_length?(str, opts)
    ) do
      {:ok, str}
    else
      {:ok, nil} ->
        {:ok, nil}

      false ->
        {:error, [count: opts[:limit], validation: :length, kind: :max]}
    end
  end

  defp valid_length?(str, %{count: :graphemes, limit: limit}) do
    String.length(str) <= limit
  end

  defp valid_length?(str, %{count: :bytes, limit: limit}) do
    byte_size(str) <= limit
  end

  @impl Ecto.ParameterizedType
  def load(data, loader, _params) do
    Ecto.Type.load(:string, data, loader)
  end

  @impl Ecto.ParameterizedType
  def dump(data, dumper, _params) do
    Ecto.Type.dump(:string, data, dumper)
  end
end
