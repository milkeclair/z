# indent a string with specified level
#
# $1: indent level (number of 2-space indents)
# $2: string to indent
# REPLY: indented string
# return: null
#
# example:
#  z.str.indent 2 "Hello" #=> "    Hello"
z.str.indent() {
  local indent_level=$1
  local str=$2

  if z.int.is_not $indent_level || z.int.lt $indent_level 0; then
    indent_level=0
  fi

  local indent=""
  for ((i=0; i<indent_level; i++)); do
    indent+="  "
  done

  z.return "${indent}${str}"
}

# split a string by a delimiter
#
# $1: string to split
# $2: delimiter (default: "|")
# REPLY: array of split strings
# return: null
#
# example:
#  z.str.split "apple|banana|cherry" "|" #=> ("apple" "banana" "cherry")
z.str.split() {
  local str=$1
  local delimiter=${2:-"|"}

  local IFS=$delimiter
  REPLY=(${=str})
}
