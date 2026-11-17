# 直前のコマンド補完の隣に、zのコマンド名を縦に表示する
#
# $@: 補完用の引数
# REPLY: null
# return: 0|1
#
# example:
#  # コマンド位置のz.arg.gを補完するコンテキスト内の場合
#  z.completion.complete._command
#  # 関数候補の例: z.arg.get
z.completion.complete._command() {
  local current_word=${PREFIX-${words[$CURRENT]:-}}
  if z.str.start_with "$current_word" z. &&
    z.int.is.zero ${#precommands:|builtin_precommands}; then
    _alternative \
      'commands:external command:_path_commands' \
      'functions:shell function:z.completion.complete._functions' \
      'aliases:alias:compadd -Qk aliases'
    return
  fi

  "$z_completion_command_function" "$@"
}

# 現在の補完位置に応じて、zの関数を補完するかドキュメントを表示する
#
# REPLY: null
# return: 0|1
#
# example:
#  # 現在の単語がz.arg.gで、候補がある補完コンテキスト内の場合
#  z.completion.complete._run
#  # 補完候補: z.arg.get
#  # return: 0
z.completion.complete._run() {
  z.completion.code._complete && return 0

  if z.completion.complete._functions; then
    return
  fi

  z.completion.complete._docs
}

# 現在の単語に対してzの関数名を補完する
#
# REPLY: null
# return: 0|1
#
# example:
#  # 現在の単語がz.arg.gで、候補がある補完コンテキスト内の場合
#  z.completion.complete._functions
#  # 補完候補: z.arg.get
#  # return: 0
z.completion.complete._functions() {
  local current_word=${PREFIX-${words[$CURRENT]:-}}
  if ! z.str.start_with "$current_word" "z."; then
    return 1
  fi

  z.completion.function._candidates "$current_word" || return 1
  z.str.split.line "$REPLY"
  local candidates=("${REPLY[@]}")
  if z.is.eq "$current_word" z. || z.int.is.positive "${z_completion_command_depth:-0}"; then
    local suffix_options=(-S "")
  else
    local suffix_options=()
  fi
  _describe -t z-functions "z functions" candidates -l "${suffix_options[@]}"
}

# 現在の補完単語付近の関数のドキュメントを表示する
#
# REPLY: null
# return: 0|1
#
# example:
#  # z.arg.getの引数位置で、その説明がキャッシュ済みの場合
#  z.completion.complete._docs
#  # 表示例（一部）: 指定インデックスの引数を取得する（1始まり）
z.completion.complete._docs() {
  z.completion.function.name._words || return 1
  local function_name=$REPLY

  z.completion.docs._get $function_name || return 1
  z.completion.docs._format "$REPLY"
  if z.var.exists compstate; then
    compstate[list]="list force messages"
  fi
  _message -r "$REPLY"
}
