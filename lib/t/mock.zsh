# mock a function
#
# $1: function name
# $2: behavior (call_original|custom code)
# REPLY: null
# return: null
#
# example:
#  z.t.mock my_func "call_original"
z.t.mock() {
  local func_name=$1
  local behavior=$2
  local original_func_name="original_$func_name"

  z.t.state.mock_originals.add $func_name "$(functions $func_name)"
  z.t.state.mock_calls.set $func_name ""
  z.t.state.mock_last_func.set $func_name

  eval "$(functions $func_name | sed "s/^$func_name/$original_func_name/")"

  if z.eq $behavior "call_original"; then
    eval "$func_name() {
      $original_func_name \"\$@\"
      z.t.state.mock_calls.add \"$func_name\" \"\$@\"
    }"
  else
    eval "$func_name() {
      $behavior
      z.t.state.mock_calls.add \"$func_name\" \"\$@\"
    }"
  fi
}

# call the original function within a mock
#
# $1: function name
# REPLY: null
# return: null
#
# example:
#  z.t.mock.call_original my_func
z.t.mock.call_original() {
  z.t.mock $1 "call_original"
}

# get the call arguments of the last call to the mocked function
# function name can be omitted to get the last mocked function
#
# $1: function name(optional)
# REPLY: array of arguments
# return: null
#
# example:
#  z.t.mock.result my_func
z.t.mock.result() {
  local func_name=$1

  if z.is_null $func_name; then
    z.t.state.mock_last_func
    func_name=$REPLY
  fi

  z.t.state.mock_calls.context $func_name
  if z.is_null $REPLY; then
    REPLY=()
  else
    z.str.split $REPLY ":"
  fi
}

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
    z.t.state.mock_last_func
    func_name=$REPLY
  fi

  z.t.state.mock_originals.context $func_name
  if z.is_not_null $REPLY; then
    eval $REPLY
    z.t.state.mock_originals.unset $func_name
  fi

  z.t.state.mock_saved_indexes.context $func_name
  if z.is_not_null $REPLY; then
    z.t.state.mock_saved_indexes.unset $func_name
  fi

  z.t.state.mock_calls.unset $func_name

  z.t.state.mock_last_func
  if z.eq $func_name $REPLY; then
    z.t.state.mock_last_func.set ""
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

  if z.t.mock.is_not_skippable $skip_unmock; then
    z.t.state.mock_originals
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
#  if z.t.mock.is_not_skippable "skip_unmock"; then ... fi
z.t.mock.is_not_skippable() {
  local skip_unmock=$1

  z.t.state.mock_originals
  z.not_eq $skip_unmock "skip_unmock" && z.is_not_null ${REPLY[@]+x}
}
