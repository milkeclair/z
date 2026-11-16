# 引数から名前付き引数を取り除く
#
# $1: 引数名（例: option）
# $@: 引数
# REPLY: 指定した名前付き引数を除いた引数
# return: null
#
# example:
#  z.arg.named.shift option option=value other_arg
#  REPLY="other_arg"
z.arg.named.shift() {
  local name=$1
  shift 2>/dev/null
  local args=("$@")
  local result=()
  local arg

  for arg in "${args[@]}"; do
    z.str.start_with "$arg" "${name}=" && continue
    result+=("$arg")
  done

  REPLY=("${result[@]}")
}
