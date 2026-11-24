# 1つのメソッド本体を収集するため、一時的なDEBUGトラップを設定する。
#
# $1: メソッド名
# $stack: 定義元の呼出しスタック。最上位は空文字列
# $file: 定義元のファイル
# $discard?: 1の場合は不正な定義を破棄する（既定: 0）
# REPLY: null
# return: 0
#
# example:
#  # 前提: Counterを定義中で、DEBUGトラップにより呼出元を監視できる
#  z.cls.capture._start increment stack="$z_cls_draw_stack" file=counter.zsh
#  # return: 0
#  # 変更後: z_cls_capture_method=increment、z_cls_capture_body=''
z.cls.capture._start() {
  z.cls.capture._watch

  local REPLY=""
  z.arg.named stack "${@:2}" && local stack=$REPLY
  z.arg.named file "${@:2}" && local file=$REPLY
  z.arg.named discard "${@:2}" default=0 && local discard=$REPLY

  typeset -g +x z_cls_capture_discard=$discard
  typeset -g +x z_cls_capture_done_result=0
  typeset -g +x z_cls_capture_stack=$stack
  typeset -g +x z_cls_capture_file=$file
  typeset -g +x z_cls_capture_body=''
  z_cls_capture_method=$1
}

# クラスの境界を監視する間だけ、利用者のDEBUGトラップを退避する。
#
# REPLY: null
# return: 0
#
# example:
#  # 前提: クラスを定義していない
#  z.cls.capture._watch
#  # return: 0
#  # 変更後: z_cls_debug_watching=1
#  z.cls.capture._stop
z.cls.capture._watch() {
  z.is.eq "${z_cls_debug_watching:-0}" 1 && return 0

  local REPLY=""

  typeset -g +x z_cls_debug_function="${functions[TRAPDEBUG]-}"
  typeset -g +x z_cls_debug_has_function=${+functions[TRAPDEBUG]}
  typeset -g +x z_cls_debug_trap=''
  typeset -g +x z_cls_debug_before=$options[debugbeforecmd]
  typeset -g +x z_cls_debug_localtraps=$options[localtraps]

  # 退避前のDEBUGトラップによる呼出元の変数への代入と区別する。
  local z_cls_debug_line

  z.str.split.line "$(trap)"
  for z_cls_debug_line in "${REPLY[@]}"; do
    z.str.start_with "$z_cls_debug_line" 'trap -- ' || continue

    z.str.split.shell "$z_cls_debug_line"
    z.arg.get "${REPLY[@]}" index=4

    z.is.eq "$REPLY" DEBUG && z_cls_debug_trap=$z_cls_debug_line
  done

  unsetopt localoptions localtraps
  setopt debugbeforecmd
  functions[TRAPDEBUG]='unsetopt localoptions; z.cls.capture._debug "$ZSH_DEBUG_CMD"'
  typeset -g +x z_cls_debug_watching=1
}

# 元のDEBUGトラップと実行タイミングの設定を復元する。
#
# REPLY: null
# return: 0
#
# example:
#  # 前提: 元のDEBUGトラップがtrap ': original' DEBUG
#  z.cls.capture._stop
#  # return: 0
#  # 変更後: trap ': original' DEBUGを復元し、収集中のメソッド名を空にする
z.cls.capture._stop() {
  z.is.eq "${z_cls_debug_watching:-0}" 1 || return 0

  z_cls_capture_method=''
  unset z_cls_debug_watching z_cls_reject_depth z_cls_reject_method z_cls_reject_stack
  unsetopt localoptions
  trap - DEBUG

  if z.is.eq "$z_cls_debug_has_function" 1; then
    functions[TRAPDEBUG]=$z_cls_debug_function
  elif z.is.not.null "$z_cls_debug_trap"; then
    eval "$z_cls_debug_trap"
  fi

  # 復元したDEBUGトラップに追加の関数呼び出しを見せずにオプションを戻す。
  if [[ $z_cls_debug_before == on ]]; then
    setopt debugbeforecmd
  else
    unsetopt debugbeforecmd
  fi

  if [[ $z_cls_debug_localtraps == on ]]; then
    setopt localtraps
  else
    unsetopt localtraps
  fi

  return 0
}

# コマンドを実行せずに収集し、終了マーカーで本体の収集を終える。
# 定義元から抜けた場合は未完了の定義を破棄する。
#
# $1: Zshが復元したコマンドの文字列
# REPLY: null
# return: 0
#
# example:
#  # 前提: runの本体を収集中のDEBUGトラップ内
#  z.cls.capture._debug 'REPLY=ready'
#  # 変更後: 本体にREPLY=readyを追記し、その場での実行を抑止
z.cls.capture._debug() {
  local REPLY=""
  local current_stack=${(j:|:)funcstack[3,-1]}

  if z.int.is.not.zero "${z_cls_reject_depth:-0}"; then
    if [[ $current_stack == "$z_cls_reject_stack" ]]; then
      z.cls.capture._skip "$1"
      return 0
    fi

    z.cls.capture._within_scope "$current_stack" "$z_cls_reject_stack" && return 0

    unset z_cls_reject_depth z_cls_reject_method z_cls_reject_stack
    if z.is.null "$z_cls_drawing"; then
      z.cls.capture._stop
      return 0
    fi
  fi

  if z.is.not.null "${z_cls_capture_method:-}"; then
    if [[ $current_stack == "$z_cls_capture_stack" ]] ||
        ! z.cls.capture._within_scope "$current_stack" "$z_cls_capture_stack"; then
      z.cls.capture._method "$1" "$current_stack"
    fi
    return 0
  fi

  if z.is.not.null "$z_cls_drawing" && ! z.cls.capture._within_scope "$current_stack" "$z_cls_draw_stack"; then
    local abandoned_class=$z_cls_drawing

    z.cls.abort
    z.io.error "Unfinished class definition $abandoned_class. Definition discarded."
  fi
}

# 拒否したクラスの対応する終端まで、宣言も通常のコマンドも飛ばす。
#
# $1: Zshが復元したコマンドの文字列
# REPLY: null
# return: 0
#
# example:
#  # 前提: 拒否したクラスを書いている間のDEBUGトラップ内
#  z.cls.capture._skip 'print unexpected'
#  # 変更後: printの実行を抑止
z.cls.capture._skip() {
  if z.int.is.not.zero "${z_cls_reject_method:-0}"; then
    z.is.eq "$1" z.cls.method.defined && z_cls_reject_method=0
  elif z.is.eq "$1" z.cls.method || z.str.start_with "$1" 'z.cls.method '; then
    local -a REPLY=()
    z.str.split.shell "$1"
    # 呼出元のSH_WORD_SPLITを単語数の判定に反映する。
    z.arr.count ${REPLY[@]}
    z.int.is.lteq "$REPLY" 2 && z_cls_reject_method=1
  elif z.is.eq "$1" z.cls.draw || z.str.start_with "$1" 'z.cls.draw '; then
    (( ++z_cls_reject_depth ))
  elif z.is.eq "$1" z.cls.drew; then
    (( --z_cls_reject_depth ))
    if z.int.is.zero "$z_cls_reject_depth"; then
      unset z_cls_reject_depth z_cls_reject_method z_cls_reject_stack
      typeset -g +x z_cls_reject_result=1
      return 0
    fi
  fi

  # DEBUGトラップから戻ったとき、拒否したコマンドの実行を抑止する。
  setopt errexit
}

# メソッドの終端を処理し、それ以外のコマンドを本体へ保存する。
#
# $1: Zshが復元したコマンドの文字列
# $2: 現在の呼出しスタック
# REPLY: null
# return: 0
#
# example:
#  # 前提: 有効なCounter.incrementの本体を収集中
#  z.cls.capture._method z.cls.method.defined "$z_cls_capture_stack"
#  # 変更後: Counter.incrementを登録し、本体の収集を終了
z.cls.capture._method() {
  if [[ $2 != "$z_cls_capture_stack" ]]; then
    z.cls.abort
    z.io.error "Unfinished class method in $z_cls_capture_file. Definition discarded."
    return 0
  fi

  if z.is.not.eq "$1" z.cls.method.defined; then
    z_cls_capture_body+="$1"$'\n'

    # 収集したコマンドはメソッド呼出しまで実行しない。
    setopt errexit
    return 0
  fi

  if z.int.is.not.zero "${z_cls_capture_discard:-0}"; then
    z.cls.abort
    z_cls_capture_done_result=1
    return 0
  fi

  z.cls.store._method "$z_cls_drawing" "$z_cls_capture_method" "$z_cls_capture_body"
  z_cls_capture_method=''
  z.is.not.null "$z_cls_drawing" || z.cls.capture._stop
}
