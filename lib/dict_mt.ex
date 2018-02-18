defmodule DictMT do
  # Trees are balanced using the condition 2^h(T) ≤ |T|^C
  @c 2

  @type key() :: binary()
  @type value() :: binary()
  @type hash() :: binary()

  @type leaf_node() :: {key(), value(), hash()}
  @type inner_node() ::
          {key(), hash() | :to_be_computed, left :: inner_node() | leaf_node(),
           right :: inner_node() | leaf_node()}
  @type tree_node() :: leaf_node() | inner_node() | :empty
  @opaque tree() :: {size :: non_neg_integer(), root_node :: tree_node()}
  @type merkle_proof() :: {hash() | merkle_proof(), hash() | merkle_proof()}

  @spec empty() :: tree()
  @doc """
  Return an empty tree.
  """
  def empty() do
    {0, :empty}
  end

  @spec size(tree()) :: non_neg_integer()
  @doc """
  Return number of elements stored in the tree.
  """
  def size({size, _}) do
    size
  end

  @spec leaf_hash(key(), value()) :: hash()
  def leaf_hash(key, value) do
    key_hash = to_string(key)
    value_hash = to_string(value)
    to_string(key_hash <> value_hash)
  end

  @spec inner_hash(hash(), hash()) :: hash()
  def inner_hash(left_hash, right_hash) do
    to_string(left_hash <> right_hash)
  end

  @spec root_hash(tree()) :: hash() | :undefined
  @doc """
  Return the hash of root node.
  """
  def root_hash({_, root_node}) do
    node_hash(root_node)
  end

  @spec merkle_proof(key(), tree()) :: merkle_proof()
  @doc """
  For a given key return a proof that, along with its value, it is contained in tree.
  Hash for root node is not included in the proof.
  """
  def merkle_proof(key, {_size, root_node}) do
    merkle_proof_node(key, root_node)
  end

  @spec merkle_proof_node(key(), tree_node()) :: merkle_proof()
  def merkle_proof_node(key, {key, value, _}) do
    {to_string(key), to_string(value)}
  end

  def merkle_proof_node(key, {inner_key, _, left, right}) do
    case key < inner_key do
      true ->
        {merkle_proof_node(key, left), node_hash(right)}

      _ ->
        {node_hash(left), merkle_proof_node(key, right)}
    end
  end

  # @spec verify_merkle_proof(key(), value(), root :: hash(), merkle_proof()) ::
  #         :ok | {:error, reason}
  #       when reason ::
  #              {key_hash_mismatch, hash()}
  #              | {value_hash_mismatch, hash()}
  #              | {root_hash_mismatch, hash()}
  @doc """
  Verify a proof against a leaf and a root node hash.
  """
  def verify_merkle_proof(key, value, root_hash, proof) do
    {kh, vh} = {to_string(key), to_string(value)}
    {pkh, pvh} = bottom_merkle_proof_pair(proof)

    cond do
      pkh !== kh ->
        {:error, {:key_hash_mismatch, pkh}}

      pvh !== vh ->
        {:error, {:value_hash_mismatch, pkh}}

      true ->
        prh = merkle_fold(proof)

        cond do
          prh !== root_hash ->
            {:error, {:root_hash_mismatch, prh}}

          true ->
            :ok
        end
    end
  end

  @spec delete(key(), tree()) :: tree()
  @doc """
  Remove key from tree. The key must be present in the tree.
  """
  def delete(key, {size, root_node}) do
    {size - 1, delete_1(key, root_node)}
  end

  @spec delete_1(key(), tree_node()) :: tree_node()
  def delete_1(key, {key, _, _}) do
    :empty
  end

  def delete_1(key, {inner_key, _, left_node, right_node}) do
    case key < inner_key do
      true ->
        case delete_1(key, left_node) do
          :empty ->
            right_node

          new_left_node ->
            {inner_key, inner_hash(node_hash(new_left_node), node_hash(right_node)),
             new_left_node, right_node}
        end

      _ ->
        case delete_1(key, right_node) do
          :empty ->
            left_node

          new_right_node ->
            {inner_key, inner_hash(node_hash(left_node), node_hash(new_right_node)), left_node,
             new_right_node}
        end
    end
  end

  @spec from_list(list({key(), value()})) :: tree()
  @doc """
  Create a tree from a list. This creates a tree by iteratively
  inserting elements and not necessarily results in a perfect balance,
  like the one obtained when running {@link from_orddict/1}.
  """
  def from_list(list) do
    from_list(list, empty())
  end

  @spec from_list(list({key(), value()}), acc :: tree()) :: tree()
  def from_list([], acc) do
    acc
  end

  def from_list([{key, value} | rest], acc) do
    from_list(rest, enter(key, value, acc))
  end

  @spec from_orddict(ord_dict :: list({key(), value()})) :: tree()
  # @equiv from_orddict(ord_dict, length(ord_dict))
  def from_orddict(ord_dict) do
    from_orddict(ord_dict, length(ord_dict))
  end

  @spec from_orddict(list({key(), value()}), size :: non_neg_integer()) :: tree()
  @doc """
  Create a perfectly balanced tree from an ordered dictionary.
  """
  def from_orddict(ord_dict, size) do
    {size, balance_orddict(ord_dict, size)}
  end

  @spec to_orddict(tree()) :: list({key(), value()})
  @doc """
  Convert tree to an orddict.
  """
  def to_orddict(tree) do
    foldr(fn kv, acc -> [kv | acc] end, [], tree)
  end

  # @spec foldr(fun(({key(), value()}, acc :: any()) -> any()), acc :: any(), tree()) -> acc :: any()
  @doc """
  Iterate through keys and values, from those with highest keys to lowest.
  """
  def foldr(fun, acc, {_, root_node}) do
    foldr_1(fun, acc, root_node)
  end

  # @spec foldr_1(fun(({key(), value()}, acc :: any()) -> any()), acc :: any(), tree_node()) -> acc :: any()
  def foldr_1(_, acc, :empty) do
    acc
  end

  def foldr_1(f, acc, _leaf_node = {key, value, _}) do
    f.({key, value}, acc)
  end

  def foldr_1(f, acc, {_, _, left, right}) do
    foldr_1(f, foldr_1(f, acc, right), left)
  end

  @spec node_hash(tree_node()) :: hash() | :undefined
  def node_hash(:empty) do
    :undefined
  end

  def node_hash({_, _, hash}) do
    hash
  end

  def node_hash({_, hash, _, _}) do
    hash
  end

  @spec enter(key(), value(), tree()) :: tree()
  @doc """
  Insert or update key and value into tree.
  """
  def enter(key, value, {size, root_node}) do
    {new_root_node, :undefined, :undefined, key_exists} = enter_1(key, value, root_node, 0, size)

    new_size =
      case key_exists do
        true -> size
        _ -> size + 1
      end

    {new_size, new_root_node}
  end

  @spec enter_1(
          key(),
          value(),
          tree_node(),
          depth :: non_neg_integer(),
          tree_size :: non_neg_integer()
        ) ::
          {tree_node(), rebalancing_count :: pos_integer() | :undefined,
           height :: non_neg_integer() | :undefined, key_exists :: boolean()}
  def enter_1(key, value, :empty, _, _) do
    {{key, value, leaf_hash(key, value)}, :undefined, :undefined, false}
  end

  def enter_1(key, value, existing_leaf_node = {existing_key, _, _}, depth, tree_size) do
    new_leaf_node = {key, value, leaf_hash(key, value)}

    case key === existing_key do
      true ->
        {new_leaf_node, :undefined, :undefined, true}

      _ ->
        new_tree_size = tree_size + 1
        new_depth = depth + 1

        {innerkey, left_node, right_node} =
          case key > existing_key do
            true ->
              {key, existing_leaf_node, new_leaf_node}

            _ ->
              {existing_key, new_leaf_node, existing_leaf_node}
          end

        case rebalancing_needed(new_tree_size, new_depth) do
          true ->
            {{innerkey, :to_be_computed, left_node, right_node}, 2, 1, false}

          _ ->
            {{innerkey, inner_hash(node_hash(left_node), node_hash(right_node)), left_node,
              right_node}, :undefined, :undefined, false}
        end
    end
  end

  def enter_1(key, value, inner_node = {inner_key, _, left_node, right_node}, depth, tree_size) do
    node_to_follow_symb =
      case key < inner_key do
        true -> :left
        _ -> :right
      end

    {node_to_follow, node_not_changed} =
      case node_to_follow_symb do
        right -> {right_node, left_node}
        left -> {left_node, right_node}
      end

    {new_node, rebalancing_count, height, key_exists} =
      enter_1(key, value, node_to_follow, depth + 1, tree_size)

    {new_left_node, new_right_node} =
      case node_to_follow_symb do
        right ->
          {left_node, new_node}

        _ ->
          {new_node, right_node}
      end

    case rebalancing_count do
      :undefined ->
        {update_inner_node(inner_node, new_left_node, new_right_node), :undefined, :undefined,
         key_exists}

      _ ->
        count = rebalancing_count + node_size(node_not_changed)
        new_height = height + 1
        new_inner_node_unbalanced = {inner_key, :to_be_computed, new_left_node, new_right_node}

        case may_be_rebalanced(count, new_height) do
          true ->
            {balance_node(new_inner_node_unbalanced, count), :undefined, :undefined, key_exists}

          _ ->
            {new_inner_node_unbalanced, count, new_height, key_exists}
        end
    end
  end

  @spec rebalancing_needed(tree_size :: non_neg_integer(), depth :: non_neg_integer()) ::
          boolean()
  def rebalancing_needed(tree_size, depth) do
    :math.pow(2, depth) > :math.pow(tree_size, @c)
  end

  @spec may_be_rebalanced(count :: non_neg_integer(), height :: non_neg_integer()) :: boolean()
  def may_be_rebalanced(count, height) do
    :math.pow(2, height) > :math.pow(count, @c)
  end

  @spec node_size(tree_node()) :: non_neg_integer()
  def node_size(:empty), do: 0
  def node_size({_, _, _}), do: 1

  def node_size({_, _, left, right}) do
    node_size(left) + node_size(right)
  end

  @spec balance_orddict(list({key(), value()}), size :: non_neg_integer()) :: tree_node()
  def balance_orddict(kv_ord_dict, size) do
    {node, []} = balance_orddict_1(kv_ord_dict, size)
    node
  end

  @spec balance_orddict_1(list({key(), value()}), size :: non_neg_integer()) ::
          {tree_node(), list({key(), value()})}
  def balance_orddict_1(ord_dict, size) when size > 1 do
    size2 = div(size, 2)
    size1 = size - size2
    {left_node, ord_dict1 = [{key, _} | _]} = balance_orddict_1(ord_dict, size1)
    {right_node, ord_dict2} = balance_orddict_1(ord_dict1, size2)

    inner_node =
      {key, inner_hash(node_hash(left_node), node_hash(right_node)), left_node, right_node}

    {inner_node, ord_dict2}
  end

  def balance_orddict_1([{key, value} | ord_dict], 1) do
    {{key, value, leaf_hash(key, value)}, ord_dict}
  end

  def balance_orddict_1(ord_dict, 0) do
    {:empty, ord_dict}
  end

  @spec node_to_orddict(tree_node()) :: list({key(), value()})
  def node_to_orddict(node) do
    foldr_1(fn kv, acc -> [kv | acc] end, [], node)
  end

  @spec balance_node(tree_node(), size :: non_neg_integer()) :: tree_node()
  def balance_node(node, size) do
    kv_ord_dict = node_to_orddict(node)
    balance_orddict(kv_ord_dict, size)
  end

  @spec balance(tree()) :: tree()
  @doc """
  Perfectly balance a tree.
  """
  def balance({size, root_node}) do
    {size, balance_orddict(node_to_orddict(root_node), size)}
  end

  @spec lookup(key(), tree()) :: value() | :none
  @doc """
  Fetch value for key from tree.
  """
  def lookup(key, {_, root_node}) do
    lookup_1(key, root_node)
  end

  @spec lookup_1(key(), inner_node() | leaf_node()) :: value() | :none
  def lookup_1(key, {key, value, _}) do
    value
  end

  def lookup_1(key, {inner_key, _, left, right}) do
    case key < inner_key do
      true ->
        lookup_1(key, left)

      _ ->
        lookup_1(key, right)
    end
  end

  def lookup_1(_, _) do
    :none
  end

  @spec update_inner_node(inner_node(), left :: tree_node(), right :: tree_node()) :: inner_node()
  def update_inner_node(node = {key, _, left, right}, new_left, new_right) do
    case Enum.map([left, right, new_left, new_right], fn el -> node_hash(el) end) do
      [left_hash, right_hash, left_hash, right_hash] ->
        # Nothing changed, no need to rehash.
        node

      [_, _, new_left_hash, new_right_hash] ->
        {key, inner_hash(new_left_hash, new_right_hash), new_left, new_right}
    end
  end

  @spec merkle_fold(merkle_proof()) :: hash()
  def merkle_fold({left, right}) do
    left_hash = merkle_fold(left)
    right_hash = merkle_fold(right)
    to_string(left_hash <> right_hash)
  end

  def merkle_fold(hash) do
    hash
  end

  @spec bottom_merkle_proof_pair(merkle_proof()) :: {hash(), hash()}
  def bottom_merkle_proof_pair({pair, hash}) when is_tuple(pair) and is_binary(hash) do
    bottom_merkle_proof_pair(pair)
  end

  def bottom_merkle_proof_pair({_hash, pair}) when is_tuple(pair) do
    bottom_merkle_proof_pair(pair)
  end

  def bottom_merkle_proof_pair(pair) do
    pair
  end

  # 
  # -ifdef(TEST).
  # empty_test_() ->
  #     [?_assertEqual(0, ?MODULE:size(empty()))].
  # 
  # %% Types for Triq.
  # key() ->
  #     binary().
  # value() ->
  #     binary().
  # kv_orddict() ->
  #     ?LET(L, list({key(), value()}), orddict:from_list(L)).
  # tree() ->
  #     %% The validity of data generated by this generator depends on the validity of the `from_list' function.
  #     %% This should not be a problem as long as the `from_list' function itself is tested.
  #     ?LET(KVO, list({key(), value()}), from_list(KVO)).
  # non_empty_tree() ->
  #     ?SUCHTHAT(Tree, tree(), element(1, Tree) > 0).
  # 
  # %% Helper functions for Triq.
  # -spec height(tree()) -> non_neg_integer().
  # height({_, RootNode}) ->
  #     node_height(RootNode).

  # -spec node_height(tree_node()) -> non_neg_integer().
  # node_height(empty) ->
  #     %% Strictly speaking, there is no height for empty tree.
  #     0;
  # node_height({_, _, _}) ->
  #     0;
  # node_height({_, _, Left, Right}) ->
  #     1 + max(node_height(Left), node_height(Right)).

  # -spec shallow_height(tree()) -> non_neg_integer().
  # shallow_height({_, RootNode}) ->
  #     node_shallow_height(RootNode).

  # -spec node_shallow_height(tree_node()) -> non_neg_integer().
  # node_shallow_height(empty) ->
  #     %% Strictly speaking, there is no height for empty tree.
  #     0;
  # node_shallow_height({_, _, _}) ->
  #     0;
  # node_shallow_height({_, _, Left, Right}) ->
  #     1 + min(node_shallow_height(Left), node_shallow_height(Right)).

  # -spec is_perfectly_balanced(tree()) -> boolean().
  # is_perfectly_balanced(Tree) ->
  #     height(Tree) - shallow_height(Tree) =< 1.

  # -spec fun_idempotent(F :: fun((X) -> X), X) -> boolean().
  # %% @doc Return true if F(X) =:= X.
  # fun_idempotent(F, X) ->
  #     F(X) =:= X.
  # 
  # prop_lookup_does_not_fetch_deleted_key() ->
  #     ?FORALL({Tree, Key, Value},
  #             {tree(), key(), value()},
  #             none =:= lookup(Key, delete(Key, enter(Key, Value, Tree)))).
  # prop_deletion_decreases_size_by_1() ->
  #     ?FORALL({Tree, Key, Value},
  #             {tree(), key(), value()},
  #             ?MODULE:size(enter(Key, Value, Tree)) - 1 =:= ?MODULE:size(delete(Key, enter(Key, Value, Tree)))).
  # prop_merkle_proofs_fold_to_root_hash() ->
  #     ?FORALL({Tree, Key, Value},
  #             {tree(), key(), value()},
  #             root_hash(enter(Key, Value, Tree)) =:= merkle_fold(merkle_proof(Key, enter(Key, Value, Tree)))).
  # prop_merkle_proofs_contain_kv_hashes_at_the_bottom() ->
  #     ?FORALL({Tree, Key, Value},
  #             {tree(), key(), value()},
  #             bottom_merkle_proof_pair(merkle_proof(Key, enter(Key, Value, Tree))) =:= {?HASH(Key), ?HASH(Value)}).
  # prop_merkle_proofs_can_be_verified() ->
  #     ?FORALL({Tree, Key, Value},
  #             {tree(), key(), value()},
  #             ok =:= verify_merkle_proof(Key, Value, root_hash(enter(Key, Value, Tree)), merkle_proof(Key, enter(Key, Value, Tree)))).
  # prop_merkle_proofs_verification_reports_mismatch_for_wrong_key() ->
  #     ?FORALL({Tree, Key, Value},
  #             {tree(), key(), value()},
  #             case verify_merkle_proof(<<"X", Key/binary>>, Value, root_hash(enter(Key, Value, Tree)), merkle_proof(Key, enter(Key, Value, Tree))) of
  #                 {error, {key_hash_mismatch, H}} when is_binary(H) ->
  #                     true;
  #                 _ ->
  #                     false
  #             end).
  # prop_merkle_proofs_verification_reports_mismatch_for_wrong_value() ->
  #     ?FORALL({Tree, Key, Value},
  #             {tree(), key(), value()},
  #             case verify_merkle_proof(Key, <<"X", Value/binary>>, root_hash(enter(Key, Value, Tree)), merkle_proof(Key, enter(Key, Value, Tree))) of
  #                 {error, {value_hash_mismatch, H}} when is_binary(H) ->
  #                     true;
  #                 _ ->
  #                     false
  #             end).
  # prop_merkle_proofs_verification_reports_mismatch_for_wrong_root_hash() ->
  #     ?FORALL({Tree, Key, Value},
  #             {tree(), key(), value()},
  #             case verify_merkle_proof(Key, Value, begin RH = root_hash(enter(Key, Value, Tree)), <<"X", RH/binary>> end, merkle_proof(Key, enter(Key, Value, Tree))) of
  #                 {error, {root_hash_mismatch, H}} when is_binary(H) ->
  #                     true;
  #                 _ ->
  #                     false
  #             end).
  # prop_from_list_size() ->
  #     ?FORALL(KVList, list({key(), value()}),
  #             length(proplists:get_keys(KVList)) =:= ?MODULE:size(from_list(KVList))).
  # prop_from_orddict_size() ->
  #     ?FORALL(KVO, kv_orddict(),
  #             length(KVO) =:= ?MODULE:size(from_list(KVO))).
  # prop_orddict_conversion_idempotence() ->
  #     ?FORALL(KVO, kv_orddict(), KVO =:= to_orddict(from_orddict(KVO))).
  # prop_from_orddict_returns_a_perfectly_balanced_tree() ->
  #     ?FORALL(KVO, kv_orddict(), is_perfectly_balanced(from_orddict(KVO))).
  # from_list_sometimes_doesnt_return_a_perfectly_balanced_tree_test() ->
  #     ?assertNotEqual(
  #        true,
  #        triq:counterexample(
  #          ?FORALL(
  #             KVList,
  #             list({key(), value()}),
  #             is_perfectly_balanced(from_list(KVList))))).
  # prop_foldr_iterates_on_proper_ordering_and_contains_no_duplicates() ->
  #     ?FORALL(Tree, tree(),
  #             fun_idempotent(
  #               fun lists:usort/1,
  #               foldr(
  #                 fun({Key, _}, Acc) -> [Key|Acc] end,
  #                 [],
  #                 Tree)
  #              )).
  # prop_enter_is_idempotent() ->
  #     ?FORALL({Tree, Key, Value},
  #             {tree(), key(), value()},
  #             fun_idempotent(
  #               fun (Tree_) -> enter(Key, Value, Tree_) end,
  #               enter(Key, Value, Tree))).
  # prop_entered_value_can_be_retrieved() ->
  #     ?FORALL({Tree, Key, Value},
  #             {tree(), key(), value()},
  #             Value =:= lookup(Key, enter(Key, Value, Tree))).
  # prop_entered_value_can_be_retrieved_after_balancing() ->
  #     ?FORALL({Tree, Key, Value},
  #             {tree(), key(), value()},
  #             Value =:= lookup(Key, balance(enter(Key, Value, Tree)))).
  # prop_height_constrained() ->
  #     ?FORALL(Tree, non_empty_tree(), math:pow(2, height(Tree)) =< math:pow(?MODULE:size(Tree), ?C)).
  # prop_balancing_yields_same_orddict() ->
  #     ?FORALL(Tree, tree(), to_orddict(Tree) =:= to_orddict(balance(Tree))).
  # prop_entering_key_second_time_does_not_increase_size() ->
  #     ?FORALL({Tree, Key, Value1, Value2},
  #             {tree(), key(), value(), value()},
  #             ?MODULE:size(enter(Key, Value1, Tree)) =:= ?MODULE:size(enter(Key, Value2, enter(Key, Value1, Tree)))).
  # prop_tree_after_explicit_balancing_is_perfectly_balanced() ->
  #     ?FORALL(Tree, tree(), is_perfectly_balanced(balance(Tree))).
  # -endif.
end
