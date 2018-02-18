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

  def audit_trail(hash_to_be_audited, tree = %MerkleTreeElixir{}) do
    index = find_index_of_leaf(0, hash_to_be_audited, tree.leafs)
    case index do
      false -> false
      _ -> audit_trail(index, )
    end
  end

  def audit_trail(index, tree = %MerkleTreeElixir{}) do
    case (index < (:math.pow(2, tree.depth)/2)) do
      
    end
  end

  def find_index_of_leaf(_, _, []), do: false
  def find_index_of_leaf(index, hash, [{hash, _}|_]), do: index
  def find_index_of_leaf(index, hash, [H|T]), do: find_index_of_leaf(index+1, hash, T)

  def is_balanced_tree({_, _, nil, nil}), do: true
  def is_balanced_tree({_, _, _, nil}), do: false
  def is_balanced_tree({_, _, _, right}), do: is_balanced_tree(right)
  def is_balanced_tree(
        %MerkleTreeElixir{
          depth: 0,
          root_hash: nil,
          left_child: nil,
          right_child: nil,
          leafs: [nil]
        }
      ),
      do: true
  def is_balanced_tree(tree = %MerkleTreeElixir{}), do: is_balanced_tree(tree.right_child)

  def append_leaf_to_unbalanced_tree(new_data, {_, data, left, nil}) do
    {1, hash_data(data, new_data), left, {0, hash_data(new_data), nil, nil}}
  end

  def append_leaf_to_unbalanced_tree(
        new_data,
        {_, _, {d, data, left_left, right_right}, right}
      ) do
    foo = append_leaf_to_unbalanced_tree(new_data, right)
    {depth, value, _, _} = foo
    {depth + 1, hash_data(data, value), {d, data, left_left, right_right}, foo}
  end

  def append_leaf_to_unbalanced_tree(new_data, tree = %MerkleTreeElixir{}) do
    %MerkleTreeElixir{
      depth: tree.depth + 1,
      root_hash: hash_data(tree.root_hash, new_data),
      left_child: tree.left_child,
      right_child: append_leaf_to_unbalanced_tree(new_data, tree.right_child),
      leafs: tree.leafs ++ [{hash_data(new_data), :right}]
    }
  end

  def append_leaf_to_balanced_tree(data, tree = %MerkleTreeElixir{}) do
    %MerkleTreeElixir{
      depth: tree.depth + 1,
      root_hash: hash_data(tree.root_hash, data),
      left_child: {tree.depth, tree.root_hash, tree.left_child, tree.right_child},
      right_child: bubble_down(tree.depth, data),
      leafs: tree.leafs ++ [{hash_data(data), :left}]
    }
  end

  def bubble_down(0, data) do
    {0, hash_data(data), nil, nil}
  end

  def bubble_down(depth, data) do
    {depth, hash_data(data), bubble_down(depth - 1, data), nil}
  end

  def hash_data(data) do
    to_string(data)
    # :crypto.hash_data(:sha256, to_string(data)) 
    # |> Base.encode16 
    # |> String.downcase
  end

  def hash_data(one, two) do
    to_string(one <> two)
    # :crypto.hash_data(:sha256, to_string(data)) 
    # |> Base.encode16 
    # |> String.downcase
  end
end
