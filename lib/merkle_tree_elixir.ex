defmodule MerkleTreeElixir do
  def tree(), do: nil

  def insert(data, nil), do: {hash(data), nil, nil}
  def insert(data, tree) do
    case is_balanced(tree) do
      true -> add_parent(data, tree)
      false -> append_to_rightmost(data, tree)
    end
  end

  def is_balanced({_, nil, nil}), do: true
  def is_balanced({_, left, nil}), do: false
  def is_balanced({_, left, right}), do: is_balanced(right)

  def append_to_rightmost(new_data, {data, left, nil}) do
    {hash(data, new_data), left, {hash(new_data), nil, nil}}
  end
  def append_to_rightmost(new_data, {data, left, right}) do
    foo = append_to_rightmost(new_data, right)
    {value, _, _} = foo
    {hash(data, value), left, foo}
  end

  def add_parent(data, {value, _, _} = tree) do
    {hash(value, data), tree, {data, nil, nil}}
  end

  defp hash(data) do
    to_string(data)
    # :crypto.hash(:sha256, to_string(data)) 
    # |> Base.encode16 
    # |> String.downcase
  end

  defp hash(one, two) do
    to_string(one <> two)
    # :crypto.hash(:sha256, to_string(data)) 
    # |> Base.encode16 
    # |> String.downcase
  end
end
