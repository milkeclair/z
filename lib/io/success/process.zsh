# 渡された引数を改行なしで標準出力へ1行に表示する
#
# $@: 引数
# $color?: 色
# $indent?: インデント
# REPLY: null
# return: null
#
# example:
#  z.io.success.oneline "success message"
z.io.success.oneline() {
  z.arg.named color $@ default=green && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY
  local args=($REPLY)

  z.is.not.null $indent && z.str.indent level=$indent message="$args" && args=($REPLY)
  z.is.not.null $color && z.str.color.decorate color=$color message="$args" && args=($REPLY)

  z.io.oneline $args
}

# 渡された引数を標準出力へ1行ずつ表示する
#
# $@: 引数
# $color?: 色
# $indent?: インデント
# REPLY: null
# return: null
#
# example:
#  z.io.success.line "success1" "success2"
z.io.success.line() {
  z.arg.named color $@ default=green && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY
  local args=($REPLY)

  z.guard; {
    z.is.null $args && return
  }

  local lines=()
  for arg in $args; do
    local line=$arg
    z.is.not.null $indent && z.str.indent level=$indent message="$line" && line=$REPLY
    lines+=($line)
  done

  z.arr.join.line $lines
  local message=$REPLY
  z.is.not.null $color && z.str.color.decorate color=$color message="$message" && message=$REPLY

  print -- $message
}
