# 渡された引数を改行なしで標準エラーへ1行に表示する
#
# $@: 引数
# $color?: 色
# $indent?: インデント
# REPLY: null
# return: null
#
# example:
#  z.io.error.oneline "error message"
z.io.error.oneline() {
  z.arg.named color $@ default=red && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY
  local args=($REPLY)

  z.is.not.null $indent && z.str.indent level=$indent message="$args" && args=($REPLY)
  z.is.not.null $color && z.str.color.decorate color=$color message="$args" && args=($REPLY)

  print -u2 -n -- $args
}

# 渡された引数を標準エラーへ1行ずつ表示する
#
# $@: 引数
# $color?: 色
# $indent?: インデント
# REPLY: null
# return: null
#
# example:
#  z.io.error.line "error1" "error2"
z.io.error.line() {
  z.arg.named color $@ default=red && local color=$REPLY
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

  print -u2 -- $message
}
