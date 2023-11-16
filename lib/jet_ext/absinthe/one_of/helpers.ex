defmodule JetExt.Absinthe.OneOf.Helpers do
  @moduledoc false

  alias Absinthe.Blueprint.Input

  @spec unwrap_data(data :: map()) :: {key :: atom(), value :: term()}
  def unwrap_data(data) do
    [{key, value}] = Enum.to_list(data)
    {key, value}
  end

  @spec unwrap_input_object(Input.Object.t()) :: Input.Value.literals()
  def unwrap_input_object(%Input.Object{fields: fields}) do
    [%Input.Field{input_value: %Input.Value{normalized: input_object}}] = fields
    input_object
  end

  @spec fold_key_to_field(data :: map(), Input.Object.t(), field :: atom()) ::
          {map(), Input.Value.literals()}
  def fold_key_to_field(data, input_object, field) do
    {value, data} = unwrap_data(data)
    {Map.put(data, field, value), unwrap_input_object(input_object)}
  end
end
