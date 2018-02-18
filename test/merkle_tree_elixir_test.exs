defmodule MerkleTreeElixirTest do
  use ExUnit.Case
  doctest MerkleTreeElixir

  test "create new tree" do
    assert(
      MerkleTreeElixir.new_tree() == %MerkleTreeElixir{
        depth: 0,
        root_hash: "",
        left_child: nil,
        right_child: nil,
        leafs: [nil]
      }
    )
  end

  test "add data to new tree" do
    tree = %MerkleTreeElixir{
      depth: 0,
      root_hash: "",
      left_child: nil,
      right_child: nil,
      leafs: [nil]
    }
    assert(MerkleTreeElixir.add_leaf_to_tree("1", tree) == %MerkleTreeElixir{
      depth: 1,
      root_hash: "1",
      left_child: {0, "1", nil, nil},
      right_child: nil,
      leafs: [{"1", :left}]
    })
  end

  test "add data to tree with 1 leaf" do
    tree = %MerkleTreeElixir{
      depth: 1,
      root_hash: "1",
      left_child: {0, "1", nil, nil},
      right_child: nil,
      leafs: [{"1", :left}]
    }
    assert(MerkleTreeElixir.add_leaf_to_tree("2", tree) == %MerkleTreeElixir{
      depth: 1,
      root_hash: "12",
      left_child: {0, "1", nil, nil},
      right_child: {0, "2", nil, nil},
      leafs: [{"1", :left}, {"2", :right}]
    })
  end

  test "detect a balanced tree" do
    tree = %MerkleTreeElixir{
      depth: 1,
      root_hash: "12",
      left_child: {0, "1", nil, nil},
      right_child: {0, "2", nil, nil},
      leafs: [{"1", :left}, {"2", :right}]
    }

    assert(MerkleTreeElixir.is_balanced_tree(tree))
    assert(MerkleTreeElixir.is_balanced_tree(MerkleTreeElixir.new_tree()))
  end

  test "detect a unbalanced tree" do
    tree = %MerkleTreeElixir{
      depth: 1,
      root_hash: "12",
      left_child: {0, "1", nil, nil},
      right_child: {0, "2", nil, nil},
      leafs: [{"1", :left}, {"2", :right}]
    }

    assert(MerkleTreeElixir.is_balanced_tree(tree))
  end

  test "detect an unbalanced tree" do
    tree = %MerkleTreeElixir{
      depth: 2,
      root_hash: "123",
      left_child: {1, "12", {0, "1", nil, nil}, {0, "2", nil, nil}},
      right_child: {1, "3", {0, "3", nil, nil}, nil},
      leafs: [{"1", :left}, {"2", :right}, {"3", :left}]
    }

    refute(MerkleTreeElixir.is_balanced_tree(tree))
  end

  test "add leaf to unbalanced tree" do
    tree = %MerkleTreeElixir{
      depth: 2,
      root_hash: "123",
      left_child: {1, "12", {0, "1", nil, nil}, {0, "2", nil, nil}},
      right_child: {1, "3", {0, "3", nil, nil}, nil},
      leafs: [{"1", :left}, {"2", :right}, {"3", :left}]
    }

    tree = MerkleTreeElixir.append_leaf_to_unbalanced_tree("4", tree)

    assert(
      tree ==
        %MerkleTreeElixir{
          depth: 3,
          root_hash: "1234",
          left_child: {1, "12", {0, "1", nil, nil}, {0, "2", nil, nil}},
          right_child: {1, "34", {0, "3", nil, nil}, {0, "4", nil, nil}},
          leafs: [{"1", :left}, {"2", :right}, {"3", :left}, {"4", :right}]
        }
    )
  end

  test "add leaf to balanced tree parent" do
    tree = %MerkleTreeElixir{
      depth: 1,
      root_hash: "12",
      left_child: {0, "1", nil, nil},
      right_child: {0, "2", nil, nil},
      leafs: [{"1", :left}, {"2", :right}]
    }

    tree = MerkleTreeElixir.append_leaf_to_balanced_tree("3", tree)

    assert(
      tree ==
        %MerkleTreeElixir{
          depth: 2,
          root_hash: "123",
          left_child: {1, "12", {0, "1", nil, nil}, {0, "2", nil, nil}},
          right_child: {1, "3", {0, "3", nil, nil}, nil},
          leafs: [{"1", :left}, {"2", :right}, {"3", :left}]
        }
    )
  end

  test "return empty list for audit_trail if hash is not a leaf in the tree" do
    tree = %MerkleTreeElixir{
      depth: 1,
      root_hash: "12",
      left_child: {0, "1", nil, nil},
      right_child: {0, "2", nil, nil},
      leafs: [{"1", :left}, {"2", :right}]
    }

    assert(MerkleTreeElixir.audit_trail("45", tree) == [])
  end

  test "find audit trail for unbalanced tree" do
    tree = %MerkleTreeElixir{
      depth: 2,
      root_hash: "123",
      left_child: {1, "12", {0, "1", nil, nil}, {0, "2", nil, nil}},
      right_child: {1, "3", {0, "3", nil, nil}, nil},
      leafs: [{"1", :left}, {"2", :right}, {"3", :left}]
    }

    assert(
      MerkleTreeElixir.audit_trail("1", tree) == [{"3", :right}, {"2", :right}, {"1", :left}]
    )

    assert(
      MerkleTreeElixir.audit_trail("2", tree) == [{"3", :right}, {"1", :left}, {"2", :right}]
    )

    assert(
      MerkleTreeElixir.audit_trail("3", tree) == [{"12", :left}, {nil, :right}, {"3", :left}]
    )
  end

  test "find audit trail for balanced tree" do
    tree = %MerkleTreeElixir{
      depth: 1,
      root_hash: "12",
      left_child: {0, "1", nil, nil},
      right_child: {0, "2", nil, nil},
      leafs: [{"1", :left}, {"2", :right}]
    }

    assert(MerkleTreeElixir.audit_trail("1", tree) == [{"2", :right}, {"1", :left}])
    assert(MerkleTreeElixir.audit_trail("2", tree) == [{"1", :left}, {"2", :right}])
  end

  test " Verify audit trail" do
    tree = %MerkleTreeElixir{
      depth: 2,
      root_hash: "123",
      left_child: {1, "12", {0, "1", nil, nil}, {0, "2", nil, nil}},
      right_child: {1, "3", {0, "3", nil, nil}, nil},
      leafs: [{"1", :left}, {"2", :right}, {"3", :left}]
    }

    audit_trail = MerkleTreeElixir.audit_trail("1", tree)
    assert(MerkleTreeElixir.verify_audit_trail(tree.root_hash, audit_trail) == true)

    audit_trail = MerkleTreeElixir.audit_trail("2", tree)
    assert(MerkleTreeElixir.verify_audit_trail(tree.root_hash, audit_trail) == true)

    audit_trail = MerkleTreeElixir.audit_trail("3", tree)
    assert(MerkleTreeElixir.verify_audit_trail(tree.root_hash, audit_trail) == true)

    audit_trail = MerkleTreeElixir.audit_trail("3124", tree)
    refute(MerkleTreeElixir.verify_audit_trail(tree.root_hash, audit_trail) == true)
  end
end
