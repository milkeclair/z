z.t.mock() {
  local func_name=$1

  z.t.state.mock_originals.add $func_name $(functions $func_name)
  z.t.state.mock_calls.set $func_name ""
  z.t.state.mock_last_func.set $func_name

  eval "$func_name() {
    z.t.state.mock_calls.add \$func_name \$@
  }"
}

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

z.t.unmock() {
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

z.t.mock.is_not_skippable() {
  local skip_unmock=$1

  z.t.state.mock_originals
  z.not_eq $skip_unmock "skip_unmock" && z.is_not_null ${REPLY[@]+x}
}
