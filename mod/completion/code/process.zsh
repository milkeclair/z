# キャッシュしたcode引数の仕様に従い、内側の補完へ切り替える
#
# REPLY: null
# return: code引数を処理した場合は0、それ以外は1
#
# example:
#  # ZLEでbehaviorにcode型を指定し、次の文字列を入力した場合
#  # 入力: z.t.mock name=example behavior='z.arg.g
#  z.completion.code._complete
#  # 補完候補の例: z.arg.get
z.completion.code._complete() {
  z.completion.code.is._active || return 1
  local function_name=${(Q)words[1]}
  local specs=$z_completion_argument_specs[$function_name]
  z.is.not.null "$specs" || return 1

  local completion_words=("${(@Q)words}")
  z.completion.argument._value "$words[$CURRENT]" || return 1
  completion_words[$CURRENT]=$REPLY
  z.completion.argument._select "specs=$specs" "current=$CURRENT" words=completion_words || return 1
  local prefix=$REPLY[1]
  local literal_values=("${REPLY[@]:1}")
  z.str.remove.prefix "$completion_words[$CURRENT]" "$prefix"
  local value=$REPLY

  if z.completion.code.is._literal "value=$value" literals=literal_values; then
    z.completion.complete._docs
    return 0
  fi

  local z_completion_code_depth=$((${z_completion_code_depth:-0} + 1))
  if z.int.is.gt "$z_completion_code_depth" 32; then
    _message -r "code argument nesting limit"
    return 0
  fi

  z.completion.code._dispatch "prefix=$prefix" "value=$value" literals=literal_values
}

# コードと許可値を、外側の引数の引用方式で補完する
#
# $prefix: 名前付き引数の接頭辞
# $value: 引数全体の値
# $literals: 許可値の配列名
# REPLY: null
# return: 0
#
# example:
#  # ZLEで「code='z.arg.g」を補完中の場合
#  local allowed_values=(noop)
#  z.completion.code._dispatch prefix=code= value=z.arg.g literals=allowed_values
#  # 補完候補の例: z.arg.get
z.completion.code._dispatch() {
  z.arg.named prefix "$@" && local prefix=$REPLY
  z.arg.named value "$@" && local value=$REPLY
  z.arg.named literals "$@" && local literals_name=$REPLY
  z.completion.code.context._prefix "value=$value" "prefix=$prefix" "input_prefix=$PREFIX" "input_suffix=$SUFFIX"
  local code_prefix=$REPLY

  if z.is.not.null "$prefix"; then
    compset -P "$prefix"
    # name=の後ろはcompsysがescapeしているため、分割前に引用を一段外す
    PREFIX=${(Q)PREFIX}
    SUFFIX=${(Q)SUFFIX}
  fi

  z.completion.code.command._complete "code=$code_prefix"
  z.var.get "$literals_name"
  local choices=("${REPLY[@]}")
  z.arr.count "${choices[@]}"
  z.int.is.positive "$REPLY" && compadd -J z-code-literals -a choices
  return 0
}
