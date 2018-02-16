defmodule MerkleTreeElixirTest do
  use ExUnit.Case
  doctest MerkleTreeElixir

  test "detect a new tree is balanced" do
    assert(MerkleTreeElixir.is_balanced({0, 1, nil, nil}))
  end

  test "detect a balanced tree" do
    tree =
      {2, 1234, {1, 12, {0, 1, nil, nil}, {0, 2, nil, nil}},
       {1, 34, {0, 3, nil, nil}, {0, 4, nil, nil}}}

    assert(MerkleTreeElixir.is_balanced(tree))
  end

  test "detect an unbalanced tree" do
    tree = {2, 1234, {1, 12, {0, 1, nil, nil}, {0, 2, nil, nil}}, {1, 34, {0, 3, nil, nil}, nil}}
    refute(MerkleTreeElixir.is_balanced(tree))
  end

  test "add rightmost leaf" do
    tree = {2, "123", {1, "12", {0, "1", nil, nil}, {0, "2", nil, nil}}, {1, "3", {0, "3", nil, nil},nil}}
    tree = MerkleTreeElixir.append_to_rightmost("4", tree)
    IO.inspect(tree)
    assert(tree ==  {2, "1234", {1, "12", {0, "1", nil, nil}, {0, "2", nil, nil}}, {1, "34", {0, "3", nil, nil},{0, "4", nil, nil}}})
  end

end
