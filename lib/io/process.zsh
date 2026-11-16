# 渡された引数を表示する
#
# $@: 引数
# $message?: 空文字列や名前付き引数に似た文字列も含めた、明示的なメッセージ
# $color?: 色
# $indent?: インデント
# REPLY: null
# return: null
#
# example:
#  z.io "hello" "world"
#  # 出力: hello world（末尾に改行）
#  z.io message="color=red"
#  # 出力: color=red（末尾に改行）
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
#  # 出力: 改行1文字
z.io.empty() {
  print -- ""
}

# 渡された引数を改行なしで1行に表示する
#
# $@: 引数
# $color?: 色
# $indent?: インデント
# REPLY: null
# return: null
#
# example:
#  z.io.oneline "hello" "world"
#  # 出力: hello world（末尾に改行なし）
#  z.io.oneline "hello"
#  z.io.oneline "world"
#  # 出力: helloworld（末尾に改行なし）
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
#  # 出力: $'\033c\n'（端末を初期化する制御文字）
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
#  z.io.null print "hello"
#  # 出力: なし
#  # return: 0
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
# $color?: 色
# $indent?: インデント
# REPLY: null
# return: null
#
# example:
#  z.io.line "hello" "world"
#  # 出力: $'hello\nworld\n'
#  z.io.line
#  # 出力: $'\n'
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
#  # 標準入力にhelloと入力してEnterを押す場合
#  z.io.read
#  # REPLY: "hello"
z.io.read() {
  read -r REPLY
}

# 渡された引数を緑色で表示する
#
# $@: 引数
# $color?: 色
# $indent?: インデント
# REPLY: null
# return: null
#
# example:
#  z.io.success "Operation completed successfully."
#  # 出力: Operation completed successfully.（緑色）
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
# $color?: 色
# $indent?: インデント
# REPLY: null
# return: null
#
# example:
#  z.io.warn "This is a warning message."
#  # 出力: This is a warning message.（黄色）
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
# $color?: 色
# $indent?: インデント
# REPLY: null
# return: null
#
# example:
#  z.io.error "error message"
#  # 標準エラー: error message（赤色）
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
