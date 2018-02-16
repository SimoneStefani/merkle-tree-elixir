defmodule MerkleTreeElixir do
  
  defstruct depth: 0, root_hash: nil, left_child: nil, right_child: nil, leafs: [nil] 
  
  def new_tree(), do: %MerkleTreeElixir{}

  def add_leaf_to_tree(data, nil), do: {0, hash_data(data), nil, nil}

  def add_leaf_to_tree(data, tree) do
    case is_balanced_tree(tree) do
      true -> append_leaf_to_balanced_tree(data, tree)
      false -> append_leaf_to_unbalanced_tree(data, tree)
    end
  end

  def is_balanced_tree({_, _, nil, nil}), do: true
  def is_balanced_tree({_, _, left, nil}), do: false
  def is_balanced_tree({_, _, left, right}), do: is_balanced_tree(right)

  def append_leaf_to_unbalanced_tree(new_data, {depth, data, left, nil}) do
    {1, hash_data(data, new_data), left, {0, hash_data(new_data), nil, nil}}
  end

  def append_leaf_to_unbalanced_tree(new_data, {depth, _, {d, data, left_left, right_right}, right}) do
    foo = append_leaf_to_unbalanced_tree(new_data, right)
    {depth, value, _, _} = foo
    {depth + 1, hash_data(data, value), {d, data, left_left, right_right}, foo}
  end

  def append_leaf_to_balanced_tree(data, {depth, value, left, right}) do
    {depth + 1, hash_data(value, data), {depth, value, left, right}, bubble_down(depth, data)}
  end

  def bubble_down(0, data) do
    {0, hash_data(data), nil, nil}
  end

  def bubble_down(depth, data) do
    {depth, hash_data(data), bubble_down(depth - 1, data), nil}
  end

  defp hash_data(data) do
    to_string(data)
    # :crypto.hash_data(:sha256, to_string(data)) 
    # |> Base.encode16 
    # |> String.downcase
  end

  defp hash_data(one, two) do
    to_string(one <> two)
    # :crypto.hash_data(:sha256, to_string(data)) 
    # |> Base.encode16 
    # |> String.downcase
  end
end
