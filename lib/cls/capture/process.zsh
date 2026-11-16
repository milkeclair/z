# 1つのメソッド本体を収集するため、一時的なDEBUGトラップを設定する。
#
# $1: メソッド名
# $2: 定義元の呼出しスタック
# $3: 定義元のファイル
# $4: 1の場合は不正な定義を破棄する
# REPLY: 変更しない
# return: 0
z.cls.capture._start() {
  typeset -g z_cls_capture_discard=${4:-0}
  typeset -g z_cls_capture_done_result=0
  typeset -g z_cls_capture_stack=$2
  typeset -g z_cls_capture_file=$3
  typeset -g z_cls_capture_body=''
  typeset -g z_cls_debug_function="${functions[TRAPDEBUG]-}"
  typeset -g z_cls_debug_has_function=${+functions[TRAPDEBUG]}
  typeset -g z_cls_debug_trap=''
  typeset -g z_cls_debug_before=$options[debugbeforecmd]
  typeset -g z_cls_debug_localtraps=$options[localtraps]

  local trap_line

  for trap_line in "${(@f)$(trap)}"; do
    z.str.start_with "$trap_line" 'trap -- ' || continue

    local -a trap_words=(${(z)trap_line})

    z.is.eq "$trap_words[4]" DEBUG && z_cls_debug_trap=$trap_line
  done

  unsetopt localtraps
  setopt debugbeforecmd
  functions[TRAPDEBUG]='unsetopt localoptions; z.cls.capture._debug "$ZSH_DEBUG_CMD"'
  z_cls_capture_method=$1
}

# 元のDEBUGトラップと実行タイミングの設定を復元する。
#
# REPLY: 変更しない
# return: 0
z.cls.capture._stop() {
  z.is.not.null "${z_cls_capture_method:-}" || return 0

  z_cls_capture_method=''
  trap - DEBUG

  if z.is.eq "$z_cls_debug_has_function" 1; then
    functions[TRAPDEBUG]=$z_cls_debug_function
  elif z.is.not.null "$z_cls_debug_trap"; then
    eval "$z_cls_debug_trap"
  fi

  z.is.eq "$z_cls_debug_before" on || unsetopt debugbeforecmd
  z.is.eq "$z_cls_debug_localtraps" off || setopt localtraps

  return 0
}

# コマンドを実行せずに収集し、終了マーカーで本体の収集を終える。
# 呼出しスタックが変わった場合は、定義元から抜けた未完了の定義を破棄する。
#
# $1: Zshが復元したコマンドの文字列
# REPLY: 変更しない
# return: 0
z.cls.capture._debug() {
  z.is.not.null "${z_cls_capture_method:-}" || return 0

  if z.is.not.eq "${(j:|:)funcstack[3,-1]}" "$z_cls_capture_stack" ||
      z.is.eq "$1" z.cls.drew || z.is.eq "$1" z.cls.abort; then
    z.cls.abort

    z.io.error "Unfinished class method in $z_cls_capture_file; definition discarded."
    return 0
  fi

  if z.is.eq "$1" z.cls.fn.done; then
    if z.is.eq "$z_cls_capture_discard" 1; then
      z.cls.abort
      z_cls_capture_done_result=1
    else
      z_cls_bodies[$z_cls_drawing:$z_cls_capture_method]=$z_cls_capture_body
      z_cls_class_methods[$z_cls_drawing]+="$z_cls_capture_method "
      z.cls.capture._stop
    fi
  else
    z_cls_capture_body+="$1"$'\n'
    setopt errexit
  fi
}
