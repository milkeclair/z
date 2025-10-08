# convert provided value into a boolean or null
#
# $1: value
# REPLY: converted value
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
z.return() {
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
