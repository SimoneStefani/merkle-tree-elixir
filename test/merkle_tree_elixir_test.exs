defmodule MerkleTreeElixirTest do
  use ExUnit.Case
  doctest MerkleTreeElixir

  test "create new tree" do
    assert(MerkleTreeElixir.new_tree() == %MerkleTreeElixir{depth: 0, root_hash: nil, left_child: nil, right_child: nil, leafs: [nil]})
  end


  test "detect a new tree is balanced" do
    assert(MerkleTreeElixir.is_balanced_tree({0, 1, nil, nil}))
  end

  test "detect a balanced tree" do
    tree =
      {2, 1234, {1, 12, {0, 1, nil, nil}, {0, 2, nil, nil}},
       {1, 34, {0, 3, nil, nil}, {0, 4, nil, nil}}}

    assert(MerkleTreeElixir.is_balanced_tree(tree))
  end

  test "detect an unbalanced tree" do
    tree = {2, 1234, {1, 12, {0, 1, nil, nil}, {0, 2, nil, nil}}, {1, 34, {0, 3, nil, nil}, nil}}
    refute(MerkleTreeElixir.is_balanced_tree(tree))
  end

  test "add leaf to unbalanced tree" do
    tree =
      {2, "123", {1, "12", {0, "1", nil, nil}, {0, "2", nil, nil}},
       {1, "3", {0, "3", nil, nil}, nil}}

    tree = MerkleTreeElixir.append_leaf_to_unbalanced_tree("4", tree)
    IO.inspect(tree)

    assert(
      tree ==
        {2, "1234", {1, "12", {0, "1", nil, nil}, {0, "2", nil, nil}},
         {1, "34", {0, "3", nil, nil}, {0, "4", nil, nil}}}
    )
  end

  test "add leaf to balanced tree parent" do
    tree = %MerkleTreeElixir{depth: 1, root_hash: "12", left_child: {0, "1", nil, nil}, right_child: {0, "2", nil, nil}, leafs: [{"1", :left} , {"2", :right}]}

    tree = MerkleTreeElixir.append_leaf_to_balanced_tree("3", tree)
    IO.inspect(tree)

    assert(
      tree ==
      %MerkleTreeElixir{depth: 2, root_hash: "123", left_child: {1, "12", {0, "1", nil, nil}, {0, "2", nil, nil}}, right_child: {1, "3", {0, "3", nil, nil}, nil}, leafs: [{"1", :left}, {"2", :right}, {"3", :left}]}
    )
  end
end
