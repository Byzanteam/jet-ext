if Code.ensure_loaded?(Absinthe) do
  defmodule JetExt.Absinthe.Types.Scalar.UUID do
    @moduledoc """
    The UUID scalar type represents a version 4(random) UUID.
    Any binary not conforming to this format will be flagged.
    """

    use Absinthe.Schema.Notation

    scalar :uuid, name: "UUID" do
      description """
      The `UUID` scalar type represents UUID4 compliant string data, represented as UTF-8
      character sequences. The UUID type is most often used to represent unique
      human-readable ID strings.
      """

      serialize(&encode/1)
      parse(&decode/1)
    end

    # credo:disable-for-next-line JetCredo.Checks.ExplicitAnyType
    @spec decode(Absinthe.Blueprint.Input.String.t()) :: {:ok, term()} | :error
    @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
    defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
      Ecto.UUID.cast(value)
    end

    defp decode(%Absinthe.Blueprint.Input.Null{}), do: {:ok, nil}
    defp decode(_data), do: :error

    defp encode(value), do: value
  end
end
