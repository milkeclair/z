z.t.expect() {
  local actual=$1
  local expect=$2
  local skip_unmock=$3

  if z.not_eq $expect $actual; then
    local expect_display=${(V)expect}
    local actual_display=${(V)actual}
    z.t.log.failure.handle "failed: expected [ $expect_display ] but got [ $actual_display ]"
  fi

  if z.t.mock.is_not_skippable $skip_unmock; then
    z.t.state.mock_originals
    for func_name in ${(k)REPLY}; do
      z.t.unmock $func_name
    done
  fi
}

z.t.expect.include() {
  local actual=$1
  local expect=$2
  local skip_unmock=$3

  if z.str.is_not_include $actual $expect; then
    z.t.log.failure.handle "failed: expected [ $expect ] to be included in [ $actual ]"
  fi

  if z.t.mock.is_not_skippable $skip_unmock; then
    z.t.state.mock_originals
    for func_name in ${(k)REPLY}; do
      z.t.unmock $func_name
    done
  fi
}

z.t.expect.exclude() {
  local actual=$1
  local expect=$2
  local skip_unmock=$3

  if z.str.is_include $actual $expect; then
    z.t.log.failure.handle "failed: expected [ $expect ] to be excluded from [ $actual ]"
  fi

  if z.t.mock.is_not_skippable $skip_unmock; then
    z.t.state.mock_originals
    for func_name in ${(k)REPLY}; do
      z.t.unmock $func_name
    done
  fi
}

z.t.expect.status() {
  local actual=$?
  local expect=$1
  local skip_unmock=$2

  z.eq $expect "true" && expect=0
  z.eq $expect "false" && expect=1

  z.t.expect $actual $skip_unmock
}

z.t.expect.status.true() {
  z.t.expect.status "true" $1 # 変数に格納した時点で$?が変わるので、$1を直接渡す
}

z.t.expect.status.false() {
  z.t.expect.status "false" $1 # 変数に格納した時点で$?が変わるので、$1を直接渡す
}

z.t.expect.reply() {
  local expect=$1
  local skip_unmock=$2

  z.t.expect $REPLY $expect $skip_unmock
}

z.t.expect.reply.null() {
  local expect=""
  local skip_unmock=$1

  z.t.expect $REPLY $expect $skip_unmock
}

z.t.expect.reply.arr() {
  local -a args=($@)
  local skip_unmock=""
  z.arg.last $args

  if z.eq $REPLY "skip_unmock"; then
    skip_unmock="skip_unmock"
    args=(${args[1,-2]})
  fi
  
  local -a expect=($args)
  local -a actual=($REPLY)

  z.arr.join $expect
  local expect_str=$REPLY
  z.arr.join $actual
  local actual_str=$REPLY

  z.t.expect $actual_str $expect_str $skip_unmock
}
