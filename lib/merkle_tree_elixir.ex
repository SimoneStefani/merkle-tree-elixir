defmodule MerkleTreeElixir do
  def tree(), do: nil

  def insert(data, nil), do: {0, hash(data), nil, nil}

  def insert(data, tree) do
    case is_balanced(tree) do
      true -> add_parent(data, tree)
      false -> append_to_rightmost(data, tree)
    end
  end

  def is_balanced({_, _, nil, nil}), do: true
  def is_balanced({_, _, left, nil}), do: false
  def is_balanced({_, _, left, right}), do: is_balanced(right)

  def append_to_rightmost(new_data, {depth, data, left, nil}) do
    {1, hash(data, new_data), left, {0, hash(new_data), nil, nil}}
  end

  def append_to_rightmost(new_data, {depth, _, {d,data,left_left,right_right}, right}) do
    foo = append_to_rightmost(new_data, right)
    {depth, value, _, _} = foo
    {depth+1, hash(data, value), {d,data,left_left,right_right}, foo}
  end

  def add_parent(data, {depth, value, _, _} = tree) do
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
