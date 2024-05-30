if Code.ensure_loaded?(URN) do
  defmodule JetExt.Ecto.URN do
    @moduledoc """
    An Ecto type for URN ([RFC 8141](https://tools.ietf.org/html/rfc8141))

    ## Examples

        # cast
        iex> cast("urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:userName")
        {:ok, %URN{
          nid: "ietf",
          nss: "params:scim:schemas:extension:enterprise:2.0:User:userName"
        }}

        iex> cast(:foo)
        :error

        iex> cast("ur:nid:nss")
        :error

        # load
        iex> load("urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:userName")
        {:ok, %URN{
          nid: "ietf",
          nss: "params:scim:schemas:extension:enterprise:2.0:User:userName"
        }}

        iex> load(URN.parse!("urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:userName"))
        {:ok, %URN{
          nid: "ietf",
          nss: "params:scim:schemas:extension:enterprise:2.0:User:userName"
        }}

        iex> load(%{})
        :error

        iex> load(:path)
        :error

        # dump

        iex> dump(URN.parse!("urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:userName"))
        {:ok, "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:userName"}

        iex> dump(%{})
        :error

        iex> dump(:path)
        :error
    """

    use Ecto.Type

    @type t() :: URN.t()

    @impl Ecto.Type
    def type, do: :string

    @impl Ecto.Type
    def embed_as(_format), do: :dump

    @impl Ecto.Type
    def cast(urn) when is_binary(urn) do
      with({:error, _reason} <- URN.parse(urn)) do
        :error
      end
    end

    def cast(%URN{} = urn), do: {:ok, urn}
    def cast(_data), do: :error

    @impl Ecto.Type
    def load(data) when is_binary(data), do: cast(data)
    def load(%URN{} = urn), do: {:ok, urn}
    def load(_data), do: :error

    @impl Ecto.Type
    def dump(%URN{} = urn), do: {:ok, URN.to_string(urn)}
    def dump(_data), do: :error

    @impl Ecto.Type
    def equal?(urn, urn), do: true
    def equal?(nil, _urn), do: false
    def equal?(_urn, nil), do: false
    def equal?(one, another), do: URN.equal?(one, another)
  end
end
