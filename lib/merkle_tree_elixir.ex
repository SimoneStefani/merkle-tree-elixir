defmodule MerkleTreeElixir do
  defstruct depth: 0, root_hash: "", left_child: nil, right_child: nil, leafs: [nil]

  def new_tree(), do: %MerkleTreeElixir{}


  def add_leaf_to_tree(new_data, %MerkleTreeElixir{ depth: 0}) do
    hash = hash_data(new_data)
    %MerkleTreeElixir{
      depth: 1,
      root_hash: hash,
      left_child: {0, hash, nil, nil},
      right_child: nil,
      leafs: [{hash, :left}]
    }
  end

  def add_leaf_to_tree(new_data, tree = %MerkleTreeElixir{}) do
    index = length(tree.leafs)
    direction = direction_of_new_leaf(length(tree.leafs))

    case is_balanced_tree(tree) do
      true ->
        %MerkleTreeElixir{
          depth: tree.depth + 1,
          root_hash: hash_data(tree.root_hash, new_data),
          left_child: {tree.depth, tree.root_hash, tree.left_child, tree.right_child},
          right_child: add_leaf_to_tree(tree.depth, new_data, index, nil),
          leafs: tree.leafs ++ [{hash_data(new_data), direction}]
        }

      false ->
        %MerkleTreeElixir{
          depth: tree.depth,
          root_hash: hash_data(tree.root_hash, new_data),
          left_child: tree.left_child,
          right_child: add_leaf_to_tree(tree.depth-1, new_data, index, tree.right_child),
          leafs: tree.leafs ++ [{hash_data(new_data), direction}]
        }
    end
  end
  
  def add_leaf_to_tree(0, new_data, _, _), do: {0, hash_data(new_data), nil, nil}
  def add_leaf_to_tree(depth, new_data, index, nil) do
    {depth, hash_data(new_data), add_leaf_to_tree(depth-1, new_data, index, nil), nil}
  end

  def add_leaf_to_tree(depth, new_data, index, {depth, hash, left_child, right_child}) do
    new_index = abs(index - :math.pow(2, depth))
    case part_of_left_subtree?(depth, new_index) do
      true ->
        {depth, hash_data(hash, new_data),
         add_leaf_to_tree(depth - 1, new_data, new_index, left_child), nil}

      false ->
        {depth, hash_data(hash, new_data), left_child,
         add_leaf_to_tree(depth - 1, new_data, new_index, right_child)}
    end
  end



  def audit_trail(hash_to_be_audited, tree = %MerkleTreeElixir{}) do
    index = Enum.find_index(tree.leafs, fn {x, _} -> x == hash_to_be_audited end)
    audit_trail(index, tree, [])
  end

  def audit_trail(nil,_,_), do: []
  def audit_trail(index, tree = %MerkleTreeElixir{}, list) do

    {_, left_hash, _, _} = tree.left_child
    {_, right_hash, _, _} = tree.right_child

    #index = index + 1
    new_index = leaf_index_in_subtree(tree.depth, index)

    case part_of_left_subtree?(tree.depth, index) do
      true -> audit_trail(new_index, tree.left_child, list ++ [{right_hash, :right}])
      false -> audit_trail(new_index, tree.right_child, list ++ [{left_hash, :left}])
    end
  end

  def audit_trail(index, {_, hash, nil, nil}, list) do
    IO.puts("final index -> #{index}")
    IO.inspect(list)
    case rem(trunc(index), 2) do
      0 -> list ++ [{hash, :left}]
      1 -> list ++ [{hash, :right}]
    end
  end

  def audit_trail(index, {_, _, left_child, nil}, list),
    do: audit_trail(index, left_child, list ++ [{nil, :right}])

  def audit_trail(index, {depth, _, left_child, right_child}, list) do

    {_, left_hash,_,_} = left_child
    {_, right_hash,_,_} = right_child

    new_index = leaf_index_in_subtree(depth, index)

    case part_of_left_subtree?(depth, index) do
      true -> audit_trail(new_index, left_child, list ++ [{right_hash, :right}])
      false -> audit_trail(new_index, right_child, list ++ [{left_hash, :left}])
    end
  end


  
  def verify_audit_trail(_, []), do: false

  def verify_audit_trail({root_hash, leaf_hash} , audit_trail) do
    reversed_audit_trail = Enum.reverse(audit_trail)
    [{head_hash,_}|_] = reversed_audit_trail
    
    case head_hash == leaf_hash do
      true -> verify_audit_trail(root_hash, "", reversed_audit_trail)
      false -> false
    end
  end
  def verify_audit_trail(root_hash, root_hash, []), do: true
  def verify_audit_trail(_, _, []), do: false

  def verify_audit_trail(root_hash, audit_hash, [{nil, :right} | tail]) do
    verify_audit_trail(root_hash, hash_data(audit_hash, ""), tail)
  end

  def verify_audit_trail(root_hash, audit_hash, [{new_hash, :right} | tail]) do
    verify_audit_trail(root_hash, hash_data(audit_hash, new_hash), tail)
  end

  def verify_audit_trail(root_hash, audit_hash, [{new_hash, :left} | tail]) do
    verify_audit_trail(root_hash, hash_data(new_hash, audit_hash), tail)
  end





  ##########################
  #### Helper Functions ####
  ##########################

  def is_balanced_tree(nil), do: false
  def is_balanced_tree({_, _, nil, nil}), do: true
  def is_balanced_tree({_, _, _, nil}), do: false
  def is_balanced_tree({_, _, _, right}), do: is_balanced_tree(right)
  def is_balanced_tree(%MerkleTreeElixir{depth: 0}), do: true
  def is_balanced_tree(tree = %MerkleTreeElixir{}), do: is_balanced_tree(tree.right_child)


  def part_of_left_subtree?(depth, index) do
    index < (:math.pow(2, depth) / 2)
  end

  def leaf_index_in_subtree(1,index_in_current_tree), do: index_in_current_tree
  def leaf_index_in_subtree(depth_of_current_tree, index_in_current_tree) do
    case part_of_left_subtree?(depth_of_current_tree, index_in_current_tree) do
      true -> index_in_current_tree
      false -> index_in_current_tree - :math.pow(2, depth_of_current_tree - 1)
    end
  end


  def direction_of_new_leaf(number_of_current_leafs) do
    case rem(number_of_current_leafs, 2) do
      0 -> :left
      1 -> :right
    end
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
