# 引数の値を別名のいずれかとして扱う
#
# $name: 対象の引数
# $as: 別名（|区切り）
# $return?: 一致した場合に返す値
# REPLY: $return|null
# return: null
#
# example:
#  z.arg.as name=--help as="-h|--help" return=0
#  # REPLY: 0
#  z.arg.as name=--version as="--version|-v" return=1
#  # REPLY: 1
#  z.arg.as name=unknown as="-h|--help" return=0
#  # REPLY: ""
z.arg.as() {
  local args=("$@")
  z.arg.named name "${args[@]}" && local name=$REPLY
  z.arg.named.shift name "${args[@]}" && args=("${REPLY[@]}")
  z.arg.named as "${args[@]}" && local as=$REPLY
  z.arg.named.shift as "${args[@]}" && args=("${REPLY[@]}")
  z.arg.named return "${args[@]}" && local return=$REPLY

  z.str.split str=$as
  local split_as=("${REPLY[@]}")
  local matched=false

  for alias in $split_as; do
    z.is.eq $name $alias && matched=true
  done

  z.is.eq $matched true &&
    REPLY=$return || REPLY=""
}

# 名前付き引数の値を取得する
#
# $1: 引数名（例: --option）
# $default?: 名前付き引数が見つからない場合の既定値
# $@: 引数
# REPLY: 名前付き引数の値|null
# return: null
#
# example:
#  z.arg.named option option=value other_arg
#  # REPLY: "value"
#  z.arg.named option other_arg default=fallback
#  # REPLY: "fallback"
z.arg.named() {
  local name=$1
  shift 2>/dev/null
  local args=("$@")
  local default=""
  local value=""
  local found=false
  local arg

  for arg in "${args[@]}"; do
    if z.str.start_with "$arg" "default="; then
      z.str.remove.prefix "$arg" "default="
      default=$REPLY
    elif z.is.false $found && z.str.start_with "$arg" "${name}="; then
      z.str.remove.prefix "$arg" "${name}="
      value=$REPLY
      found=true
    fi
  done

  REPLY=${value:-$default}
}

# 名前付き引数を解析し、残りの引数を集める
#
# $input: 入力配列の名前（読み取り専用）
# $named: 最初に一致した値で更新する、既定値の連想配列名
# $rest: 残った文字列の引数を受け取る配列名
# REPLY: null
# return: 解析できた場合は0、それ以外は1
#
# example:
#  local -a input_args=("a" "delimiter=," "b")
#  local -A parsed_named=([delimiter]=" ")
#  local -a parsed_args=()
#  z.arg.parse input=input_args named=parsed_named rest=parsed_args
#  # return: 0
#  # 変更後: parsed_named[delimiter]=","、parsed_args=("a" "b")
z.arg.parse() {
  z.arg.named input "$@" && local input_name=$REPLY
  z.arg.named named "$@" && local named_name=$REPLY
  z.arg.named rest "$@" && local rest_name=$REPLY

  z.guard; {
    if ! z.var.exists "$input_name" || ! z.var.exists "$named_name" ||
      ! z.var.exists "$rest_name"; then
      z.io.error "z.arg.parse: input, named and rest arrays are required"
      return 1
    fi
  }

  z.var.get $input_name && local args=("${REPLY[@]}")
  z.hash.entries $named_name && local -A values=("${REPLY[@]}")
  z.arg.parse._names values && local accepted_names=("${REPLY[@]}")

  local remaining=()
  local -A found=()
  local arg name

  for arg in "${args[@]}"; do
    local matched=false

    for name in "${accepted_names[@]}"; do
      z.str.start_with "$arg" "${name}=" || continue

      if ! z.is.true "${found[$name]:-false}"; then
        z.str.remove.prefix "$arg" "${name}="
        local value=$REPLY
        z.is.null "$value" && value=${values[$name]}
        values[$name]=$value
        found[$name]=true
      fi

      matched=true
      break
    done

    z.is.false $matched && remaining+=("$arg")
  done

  z.hash.entries values
  set -A "$named_name" "${REPLY[@]}"
  set -A "$rest_name" "${remaining[@]}"
  REPLY=""
}
