defmodule DictMTTest do
  use ExUnit.Case
  doctest DictMT

  test "an empty tree has zero nodes" do
    assert(DictMT.size(DictMT.empty()))
  end

end