defmodule JetExt.Ecto.Version do
  @moduledoc """
  A Ecto Type for `Version` that follows [SemVer 2.0](https://semver.org/).

  ## Examples

    # cast
    iex> cast("2.0.1-alpha1")
    {:ok, %Version{
      major: 2,
      minor: 0,
      patch: 1,
      pre: ["alpha1"]
    }}

    iex> cast(Version.parse!("2.0.1-alpha1"))
    {:ok, %Version{
      major: 2,
      minor: 0,
      patch: 1,
      pre: ["alpha1"]
    }}

    iex> cast("1")
    :error

    iex> cast(:foo)
    :error

    # load
    iex> load("2.0.1-alpha1")
    {:ok, %Version{
      major: 2,
      minor: 0,
      patch: 1,
      pre: ["alpha1"]
    }}

    iex> load(Version.parse!("2.0.1-alpha1"))
    {:ok, %Version{
      major: 2,
      minor: 0,
      patch: 1,
      pre: ["alpha1"]
    }}

    iex> load("1")
    :error

    iex> load(:foo)
    :error

    # dump

    iex> dump(Version.parse!("2.0.1-alpha1"))
    {:ok, "2.0.1-alpha1"}

    iex> dump(%{})
    :error

    iex> dump(:foo)
    :error
  """

  use Ecto.Type

  @impl Ecto.Type
  def type, do: :string

  @impl Ecto.Type
  def cast(version) when is_binary(version) do
    Version.parse(version)
  end

  def cast(%Version{} = version), do: {:ok, version}
  def cast(_other), do: :error

  @impl Ecto.Type
  def load(data) when is_binary(data) do
    Version.parse(data)
  end

  def load(%Version{} = version), do: {:ok, version}
  def load(_other), do: :error

  @impl Ecto.Type
  def dump(%Version{} = version), do: {:ok, Version.to_string(version)}
  def dump(_other), do: :error
end
