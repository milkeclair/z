# convert provided value into a boolean or null
# or combine multiple values into REPLY
#
# $@: value(s)
# REPLY: converted value or array of values
# return: exit code
#
# example:
#  z.return 0 #=> REPLY=0
#  z.return "true" #=> REPLY=0
#
#  z.return 1 #=> REPLY=1
#  z.return "false" #=> REPLY=1
#
#  z.return "null" #=> REPLY=""
#  z.return "void" #=> REPLY=""
#  z.return "" #=> REPLY=""
#
#  z.return "some string" #=> REPLY="some string"
#  z.return "a" "b" "c"   #=> REPLY=("a" "b" "c")
z.return() {
  if (( $# <= 1 )); then
    local value=""
    if (( $# == 1 )); then
      arg=$1
      [[ $arg == keep_empty=* ]] || value=$arg
    fi
  else
    local keep_empty=false
    local filtered_args=()

    for arg in "$@"; do
      if [[ ( $keep_empty == false || $keep_empty == 1 ) && $arg == keep_empty=* ]]; then
        keep_empty=${arg#keep_empty=}
      else
        filtered_args+=("$arg")
      fi
    done

    if (( ${#filtered_args[@]} > 1 )); then
      if [[ $keep_empty == true || $keep_empty == 0 ]]; then
        REPLY=("${filtered_args[@]}")
      else
        REPLY=(${filtered_args[@]})
      fi
      return
    fi

    local value=$filtered_args[1]
  fi

  case $value in
  0|"true")
    REPLY=0
    ;;
  1|"false")
    REPLY=1
    ;;
  "null"|"void"|"")
    REPLY=""
    ;;
  *)
    REPLY=$value
    ;;
  esac
}

# return a hash by its name
#
# $1: name of the hash
# REPLY: array of key-value pairs (key1 value1 key2 value2 ...)
# return: null
#
# example:
#   local -A hash
#   hash[name]="John"
#   hash[age]="30"
#
#   z.return.hash hash
#   local -A result=($REPLY)
#   echo ${result[name]}  # outputs "John"
z.return.hash() {
  local hash_name=$1
  REPLY=(${(Pkv)hash_name})
}
