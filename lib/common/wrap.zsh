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
  if z.int.gt $# 1; then
    REPLY=($@)
    return
  fi

  local value=$1

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
