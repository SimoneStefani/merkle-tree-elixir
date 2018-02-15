defmodule MerkleTreeElixirTest do
  use ExUnit.Case
  doctest MerkleTreeElixir

  test "detect a new tree is balanced" do
    assert(MerkleTreeElixir.is_balanced({1, nil, nil}))
  end

  test "detect a balanced tree" do
    tree = {1234, {12, {1, nil, nil}, {2, nil, nil}}, {34, {3, nil, nil}, {4, nil, nil}}}
    assert(MerkleTreeElixir.is_balanced(tree))
  end

  test "detect an unbalanced tree" do
    tree = {1234, {12, {1, nil, nil}, {2, nil, nil}}, {34, {3, nil, nil}, nil}}
    refute(MerkleTreeElixir.is_balanced(tree))
  end
end
