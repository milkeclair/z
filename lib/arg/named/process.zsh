# remove named argument from arguments
#
# $1: name of the argument (e.g. option)
# $@: arguments
# REPLY: arguments without the named argument
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
