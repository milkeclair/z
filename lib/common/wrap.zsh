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
  local keep_empty=false
  local filtered_args=()

  for arg in "$@"; do
    if z.is.false $keep_empty && z.str.is.match "$arg" "keep_empty=*"; then
      keep_empty=${arg#keep_empty=}
    else
      filtered_args+=("$arg")
    fi
  done

  if z.int.is.gt ${#filtered_args[@]} 1; then
    if z.is.true $keep_empty; then
      REPLY=("${filtered_args[@]}")
    else
      REPLY=(${filtered_args[@]})
    fi
    return
  fi

  local value=$filtered_args[1]

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
