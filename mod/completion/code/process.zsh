# キャッシュでcode型と分かる引数の補完を、内側のコマンドへ切り替える
#
# REPLY: null
# return: code引数を処理した場合は0、それ以外は1
#
# example:
#  # ZLE内でbehaviorにcode型が指定されている場合
#  # 入力: z.t.mock name=example behavior='z.arg.g
#  z.completion.code._complete
#  # 補完候補の例: z.arg.get
z.completion.code._complete() {
  (( ${+compstate} && CURRENT > 1 )) || return 1
  (( ${#words[CURRENT]} <= 1048576 )) || return 1

  local input_prefix=$PREFIX
  local input_suffix=$SUFFIX
  local function_name=${(Q)words[1]}
  local specs=${z_completion_argument_specs[$function_name]}
  [[ -n $specs ]] || return 1

  local completion_words=("${(@Q)words}")
  z.completion.argument._value "$words[$CURRENT]" || return 1
  completion_words[$CURRENT]=$REPLY
  z.completion.argument._select "$specs" "$CURRENT" "${completion_words[@]}" || return 1
  local prefix=$REPLY[1]
  local literals=("${REPLY[@]:1}")
  local value=${completion_words[$CURRENT]#"$prefix"}
  local code_prefix=$value
  if [[ -n $input_suffix ]]; then
    local candidate=${input_prefix#"$prefix"}
    if [[ $value == "$candidate"* ]]; then
      code_prefix=$candidate
    else
      code_prefix=${(Q)candidate}
    fi
  fi

  local literal
  for literal in "${literals[@]}"; do
    if [[ $value == "$literal" ]]; then
      z.completion.complete._docs
      return 0
    fi
  done

  local z_completion_code_depth=$(( ${z_completion_code_depth:-0} + 1 ))
  if ((z_completion_code_depth > 32)); then
    _message -r "code argument nesting limit"
    return 0
  fi

  if z.is.not.null "$prefix"; then
    compset -P "$prefix"
    # name=の後ろはcompsysがescapeしているため、内側を分割する前に引用を一段外す
    PREFIX=${(Q)PREFIX}
    SUFFIX=${(Q)SUFFIX}
  fi
  z.completion.code._commands "$code_prefix"
  if (( ${#literals[@]} )); then
    compadd -J z-code-literals -a literals
  fi

  return 0
}

# Zsh標準の引用解析と字句分割で、コード内の現在のコマンドを補完する
#
# $1: カーソルより前のコード文字列
# REPLY: null
# return: 標準の補完結果
#
# example:
#  # ZLE内でコード文字列の補完位置にいる場合
#  z.completion.code._commands "z.arg.g"
#  # 補完候補の例: z.arg.get
z.completion.code._commands() {
  local code_prefix=$1
  local tokens=("${(@Z+cn+)code_prefix}")
  [[ $tokens[-1] == \#* ]] && return 1
  [[ $code_prefix == *[[:space:]] ]] && tokens+=("")

  local command_start=1
  local idx
  for ((idx=1; idx<${#tokens[@]}; idx++)); do
    case $tokens[$idx] in
      ';'|'&&'|'||'|'|'|'|&'|'&'|$'\n')
        command_start=$((idx + 1))
        ;;
      if|then|else|elif|while|until|do|coproc|time)
        ((idx == command_start)) && command_start=$((idx + 1))
        ;;
    esac
  done

  compset -q
  if ((command_start > 1)); then
    local suffix_words=("${words[@]:$CURRENT}")
    words=("${tokens[@]:$((command_start - 1))}" "${suffix_words[@]}")
    CURRENT=$((${#tokens[@]} - command_start + 1))
  fi

  _normal
}
