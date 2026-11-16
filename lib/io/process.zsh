# 渡された引数を表示する
#
# $@: 引数
# $message?: 空文字列や名前付き引数に似た文字列も含めた、明示的なメッセージ
# $color?: 色名
# $indent?: インデントの段階
# REPLY: null
# return: null
#
# example:
#  z.io "hello" "world" #=> hello world
#  z.io message="color=red" #=> color=red
z.io() {
  z.arg.named color "$@" && local color=$REPLY
  z.arg.named indent "$@" && local indent=$REPLY
  z.arg.named.shift color "$@"
  z.arg.named.shift indent "${REPLY[@]}"
  local args=("${REPLY[@]}")

  local arg
  for arg in "${args[@]}"; do
    z.str.start_with "$arg" "message=" || continue
    z.arg.named message "${args[@]}" && args=("$REPLY")
    break
  done

  z.guard; {
    z.arr.count "${args[@]}"
    z.int.is.zero $REPLY && return
  }

  z.is.not.null $indent && z.str.indent level=$indent message="$args" && args=("$REPLY")
  z.is.not.null $color && z.str.color.decorate color=$color message="$args" && args=("$REPLY")
  print -r -- "${args[@]}"
}

# 空行を出力する
#
# REPLY: null
# return: null
#
# example:
#  z.io.empty
z.io.empty() {
  print -- ""
}

# 渡された引数を改行なしで1行に表示する
#
# $@: 引数
# $color?: 色名
# $indent?: インデントの段階
# REPLY: null
# return: null
#
# example:
#  z.io.oneline "hello" "world" #=> hello world
#  z.io.oneline "hello"
#  z.io.oneline "world"         #=> helloworld
z.io.oneline() {
  z.arg.named color $@ && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY
  local args=($REPLY)

  z.guard; {
    z.is.null $args && return
  }

  z.is.not.null $indent && z.str.indent level=$indent message="$args" && args=($REPLY)
  z.is.not.null $color && z.str.color.decorate color=$color message="$args" && args=($REPLY)
  print -n -- $args
}

# 端末の画面を消去する
#
# REPLY: null
# return: null
#
# example:
#  z.io.clear
z.io.clear() {
  print "\033c"
}

# コマンドを実行し、標準出力と標準エラーを/dev/nullへ送る
#
# $@: コマンドとその引数
# REPLY: null
# return: null
#
# example:
#  z.io.null ls -la
z.io.null() {
  z.arr.count $@
  if z.int.is.eq $REPLY 0; then
    cat >/dev/null 2>&1
  else
    "$@" >/dev/null 2>&1
  fi
}

# 渡された引数を1行ずつ表示する
#
# $@: 引数
# $color?: 色名
# $indent?: インデントの段階
# REPLY: null
# return: null
#
# example:
#  z.io.line "hello" "world" #=> hello\nworld
#  z.io.line #=> (empty line)
z.io.line() {
  z.arg.named color $@ && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY
  local args=($REPLY)

  z.guard; {
    z.is.null $args && { z.io.empty; return; }
  }

  local lines=()
  for arg in $args; do
    local line=$arg

    z.is.not.null $indent && z.str.indent level=$indent message="$line" && line=$REPLY
    z.is.not.null $color && z.str.color.decorate color=$color message="$line" && line=$REPLY
    lines+=($line)
  done

  print -l -- $lines
}

# 標準入力から1行を読み、REPLYへ保存する
#
# REPLY: 入力行
# return: null
#
# example:
#  z.io.read #=> REPLY="input line"
z.io.read() {
  read -r REPLY
}

# 渡された引数を緑色で表示する
#
# $@: 引数
# $color?: 色名
# $indent?: インデントの段階
# REPLY: null
# return: null
#
# example:
#  z.io.success "Operation completed successfully."
z.io.success() {
  z.arg.named color $@ default=green && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY

  z.io $REPLY color=$color indent=$indent
}

# 渡された引数を黄色で表示する
#
# $@: 引数
# $color?: 色名
# $indent?: インデントの段階
# REPLY: null
# return: null
#
# example:
#  z.io.warn "This is a warning message."
z.io.warn() {
  z.arg.named color $@ default=yellow && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY

  z.io $REPLY color=$color indent=$indent
}

# 渡された引数を標準エラーへ表示する
#
# $@: 引数
# $color?: 色名
# $indent?: インデントの段階
# REPLY: null
# return: null
#
# example:
#  z.io.error "error message"
z.io.error() {
  z.arg.named color $@ default=red && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY
  local args=($REPLY)

  z.guard; {
    z.is.null $args && return
  }

  z.is.not.null $indent && z.str.indent level=$indent message="$args" && args=($REPLY)
  z.is.not.null $color && z.str.color.decorate color=$color message="$args" && args=($REPLY)

  print -u2 -- $args
}
