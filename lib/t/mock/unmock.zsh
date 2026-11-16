# 関数のモックを解除する
# 関数名を省略すると、最後にモックした関数のモックを解除する
#
# $name?: 関数名
# REPLY: null
# return: null
#
# example:
#  z.t.mock.unmock name=my_func
z.t.mock.unmock() {
  z.arg.named name $@ && local func_name=$REPLY
  local nonfunctional="_nonfunctional"

  if z.is.null $func_name; then
    z.t._state.mock_last_func
    func_name=$REPLY
  fi

  local original_func_name="original_$func_name"

  z.t._state.mock_originals.context $func_name
  if z.is.not.null $REPLY; then
    if z.is.eq $REPLY $nonfunctional; then
      unfunction $func_name 2>/dev/null
      unfunction $original_func_name 2>/dev/null
    else
      eval $REPLY
    fi
    z.t._state.mock_originals.unset $func_name
  fi

  z.t._state.mock_calls.unset $func_name

  z.t._state.mock_last_func
  if z.is.eq $func_name $REPLY; then
    z.t._state.mock_last_func.set ""
  fi
}

# すべての関数のモックを解除する
# 引数が"skip_unmock"ならモック解除を省略する
#
# $skip_unmock?: モック解除を省略するか
# REPLY: null
# return: null
#
# example:
#  z.t.mock.unmock.all
z.t.mock.unmock.all() {
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  if z.t.mock.unmock._is_not_skippable $skip_unmock; then
    z.t._state.mock_originals
    for func_name in $REPLY; do
      z.t.mock.unmock name=$func_name
    done
  fi
}

# モック解除を省略しないか確認する
#
# $1?: モック解除を省略するか
# REPLY: null
# 0|1を返す
#
# example:
#  if z.t.mock.unmock._is_not_skippable true; then ... fi
z.t.mock.unmock._is_not_skippable() {
  local skip_unmock=$1

  z.is.true $skip_unmock && return 1

  z.t._state.mock_originals
  z.is.not.null ${REPLY[@]+x}
}
