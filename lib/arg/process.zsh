# argument value as one of the aliases
#
# $1: target argument
# $2: aliases (| separated)
# $3: return value when matched (optional)
# REPLY: $3|null
# return: null
#
# example:
#  z.arg.as $1 "-h|--help" 0 #=> REPLY=0
#  z.arg.as $1 "--version|-v" 1 #=> REPLY=1
#  z.arg.as $1 "-h|--help" #=> REPLY=""
z.arg.as() {
  local arg=$1
  local aliases=$2
  local return_value=$3

  if z.is_null $return_value; then
    arg=""
    aliases=$1
    return_value=$2
  fi

  z.str.split $aliases
  local -a split_aliases=($REPLY[@])
  local matched="false"

  for alias in $split_aliases; do
    z.eq $arg $alias && matched="true"
  done

  z.eq $matched "true" &&
    z.return $return_value || z.return
}
