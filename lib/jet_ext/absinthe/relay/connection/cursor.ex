defmodule JetExt.Absinthe.Relay.Connection.Cursor do
  @moduledoc false

  alias JetExt.Absinthe.Relay.Connection.Config
  alias JetExt.Absinthe.Relay.Connection.Cursor.Extractor

  @spec decode(binary()) :: {:ok, term()} | {:error, term()}
  def decode(nil), do: {:ok, nil}

  def decode(encoded_cursor) do
    encoded_cursor
    |> Base.url_decode64!(padding: false)
    |> :erlang.binary_to_term([:safe])
  rescue
    ArgumentError ->
      {:error, "`#{encoded_cursor}` does not appear to be a valid cursor."}
  else
    cursor ->
      {:ok, cursor}
  end

  # schemaless_row is a map not a struct
  @spec encode_record(map(), Config.t()) :: binary()
  def encode_record(%{} = map, %Config{} = config) do
    map
    |> Extractor.extract(Keyword.keys(config.cursor_fields))
    |> :erlang.term_to_binary()
    |> Base.url_encode64(padding: false)
  end
end
