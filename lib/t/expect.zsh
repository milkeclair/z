# expect that actual equals expect
#
# $1: actual value
# $2: expected value
# $3: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  z.t.expect $actual $expect
z.t.expect() {
  local actual=$1
  local expect=$2
  local skip_unmock=$3

  if z.not_eq $expect $actual; then
    local expect_display=${(V)expect}
    local actual_display=${(V)actual}
    z.t.log.failure.handle "failed: expected [ $expect_display ] but got [ $actual_display ]"
  fi

  z.t.mock.unmock.all $skip_unmock
}

# expect that actual does not equal expect
#
# $1: actual value
# $2: expected value
# $3: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  z.t.expect.not $actual $expect
z.t.expect.not() {
  local actual=$1
  local expect=$2
  local skip_unmock=$3

  if z.eq $expect $actual; then
    local expect_display=${(V)expect}
    local actual_display=${(V)actual}
    z.t.log.failure.handle "failed: expected not [ $expect_display ] but got [ $actual_display ]"
  fi

  z.t.mock.unmock.all $skip_unmock
}

# expect that actual includes expect
#
# $1: actual value
# $2: expected substring
# $3: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  z.t.expect.include $actual $expect
z.t.expect.include() {
  local actual=$1
  local expect=$2
  local skip_unmock=$3

  if z.str.is_not_include $actual $expect; then
    z.t.log.failure.handle "failed: expected [ $expect ] to be included in [ $actual ]"
  fi

  z.t.mock.unmock.all $skip_unmock
}

# expect that actual excludes expect
#
# $1: actual value
# $2: expected substring
# $3: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  z.t.expect.exclude $actual $expect
z.t.expect.exclude() {
  local actual=$1
  local expect=$2
  local skip_unmock=$3

  if z.str.is_include $actual $expect; then
    z.t.log.failure.handle "failed: expected [ $expect ] to be excluded from [ $actual ]"
  fi

  z.t.mock.unmock.all $skip_unmock
}

# expect that last command's exit status equals expect
#
# $1: expected status (0 for true, 1 for false, "true" for 0, "false" for 1)
# $2: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  some_command
#  z.t.expect.status 0
z.t.expect.status() {
  local actual=$?
  local expect=$1
  local skip_unmock=$2

  z.eq $expect "true" && expect=0
  z.eq $expect "false" && expect=1

  z.t.expect "$actual" "$expect" "$skip_unmock"
}

# expect that last command's exit status is true (0)
#
# $1: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  some_command
#  z.t.expect.status.true
z.t.expect.status.true() {
  z.t.expect.status "true" $1 # 変数に格納した時点で$?が変わるので、$1を直接渡す
}

# expect that last command's exit status is false (1)
#
# $1: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  some_command
#  z.t.expect.status.false
z.t.expect.status.false() {
  z.t.expect.status "false" $1 # 変数に格納した時点で$?が変わるので、$1を直接渡す
}

# expect that REPLY equals expect
#
# $1: expected value
# $2: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  REPLY="some value"
#  z.t.expect.reply "some value"
z.t.expect.reply() {
  local expect=$1
  local skip_unmock=$2

  z.t.expect "$REPLY" "$expect" "$skip_unmock"
}

# expect that REPLY is null (empty string)
#
# $1: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  REPLY=""
#  z.t.expect.reply.null
z.t.expect.reply.null() {
  local expect=""
  local skip_unmock=$1

  z.t.expect "$REPLY" "$expect" "$skip_unmock"
}

# expect that REPLY is not null (not empty string)
#
# $1: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  REPLY="some value"
#  z.t.expect.reply.not_null
z.t.expect.reply.not_null() {
  local expect=""
  local skip_unmock=$1

  z.t.expect.not "$REPLY" "$expect" "$skip_unmock"
}

# expect that REPLY array equals expect array
#
# $@: expected array elements
# REPLY: null
# return: null
#
# example:
#  REPLY=("a" "b" "c")
#  z.t.expect.reply.arr "a" "b" "c"
z.t.expect.reply.arr() {
  local -a actual=($REPLY)

  local -a args=($@)
  local skip_unmock=""
  z.arg.last $args

  if z.eq $REPLY "skip_unmock"; then
    skip_unmock="skip_unmock"
    args=(${args[1,-2]})
  fi

  local -a expect=($args)

  z.arr.join ${expect[@]}
  local expect_str=$REPLY
  z.arr.join ${actual[@]}
  local actual_str=$REPLY

  z.t.expect "$actual_str" "$expect_str" "$skip_unmock"
}

# expect that REPLY includes expect
#
# $1: expected substring
# $2: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  REPLY="some long string"
#  z.t.expect.reply.include "long"
z.t.expect.reply.include() {
  local expect=$1
  local skip_unmock=$2

  z.t.expect.include $REPLY $expect $skip_unmock
}
