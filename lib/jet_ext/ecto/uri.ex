defmodule JetExt.Ecto.Uri do
  @moduledoc """
  An Ecto type for URI ([RFC 3986](https://tools.ietf.org/html/rfc3986)).


  ## Examples

    # cast
    iex> cast("https://elixir-lang.org/")
    {:ok, %URI{
      fragment: nil,
      host: "elixir-lang.org",
      path: "/",
      port: 443,
      query: nil,
      scheme: "https",
      userinfo: nil
    }}

    iex> cast("/foo")
    {:ok, %URI{
      fragment: nil,
      host: nil,
      path: "/foo",
      port: nil,
      query: nil,
      scheme: nil,
      userinfo: nil
    }}

    iex> cast(:foo)
    :error

    iex> cast("/invalid_greater_than_in_path/>")
    {:error, part: ">"}

    # load
    iex> load("https://elixir-lang.org/")
    {:ok, %URI{
      fragment: nil,
      host: "elixir-lang.org",
      path: "/",
      port: 443,
      query: nil,
      scheme: "https",
      userinfo: nil
    }}

    iex> load(URI.new!("https://elixir-lang.org/"))
    {:ok, %URI{
      fragment: nil,
      host: "elixir-lang.org",
      path: "/",
      port: 443,
      query: nil,
      scheme: "https",
      userinfo: nil
    }}

    iex> load(%{})
    :error

    iex> load(:path)
    :error

    # dump

    iex> dump(URI.new!("https://elixir-lang.org/"))
    {:ok, "https://elixir-lang.org/"}

    iex> dump(%{})
    :error

    iex> dump(:path)
    :error
  """

  use Ecto.Type

  @impl true
  def type, do: :string

  @impl true
  def cast(uri) when is_binary(uri) do
    with({:error, part} <- URI.new(uri)) do
      {:error, [part: part]}
    end
  end

  def cast(%URI{} = uri), do: {:ok, uri}
  def cast(_data), do: :error

  @impl true
  def load(data) when is_binary(data), do: cast(data)
  def load(%URI{} = uri), do: {:ok, uri}
  def load(_data), do: :error

  @impl true
  def dump(%URI{} = uri), do: {:ok, URI.to_string(uri)}
  def dump(_data), do: :error
end
