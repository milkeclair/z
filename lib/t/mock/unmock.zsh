# unmock a function
# function name can be omitted to unmock the last mocked function
#
# $1: function name(optional)
# REPLY: null
# return: null
#
# example:
#  z.t.mock.unmock my_func
z.t.mock.unmock() {
  local func_name=$1

  if z.is_null $func_name; then
    z.t._state.mock_last_func
    func_name=$REPLY
  fi

  z.t._state.mock_originals.context $func_name
  if z.is_not_null $REPLY; then
    eval $REPLY
    z.t._state.mock_originals.unset $func_name
  fi

  z.t._state.mock_saved_indexes.context $func_name
  if z.is_not_null $REPLY; then
    z.t._state.mock_saved_indexes.unset $func_name
  fi

  z.t._state.mock_calls.unset $func_name

  z.t._state.mock_last_func
  if z.eq $func_name $REPLY; then
    z.t._state.mock_last_func.set ""
  fi
}

# unmock all mocked functions
# skip unmocking if the argument is "skip_unmock"
#
# $1: skip unmock(optional)
# REPLY: null
# return: null
#
# example:
#  z.t.mock.unmock.all
z.t.mock.unmock.all() {
  local skip_unmock=$1

  if z.t.mock.unmock._is_not_skippable $skip_unmock; then
    z.t._state.mock_originals
    for func_name in $REPLY; do
      z.t.mock.unmock $func_name
    done
  fi
}

# check if unmocking is not skipped
#
# $1: skip unmock(optional)
# REPLY: null
# return 0|1
#
# example:
#  if z.t.mock.unmock._is_not_skippable "skip_unmock"; then ... fi
z.t.mock.unmock._is_not_skippable() {
  local skip_unmock=$1

  z.t._state.mock_originals
  z.not_eq $skip_unmock "skip_unmock" && z.is_not_null ${REPLY[@]+x}
}
