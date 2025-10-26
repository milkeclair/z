# indent a string with specified level
#
# $level: indent level (number of 2-space indents)
# $message: string to indent
# REPLY: indented string
# return: null
#
# example:
#  z.str.indent level=2 message="Hello" #=> "    Hello"
z.str.indent() {
  z.arg.named level $@
  local level=$REPLY
  z.arg.named message $@
  local message=$REPLY

  if z.int.not_match $level || z.int.lt $level 0; then
    level=0
  fi

  local indent=""
  for ((i=0; i<level; i++)); do
    indent+="  "
  done

  z.return "${indent}${message}"
}

# split a string by a delimiter
#
# $str: string to split
# $delimiter?: delimiter (default: "|")
# REPLY: array of split strings
# return: null
#
# example:
#  z.str.split str="apple|banana|cherry" delimiter=| #=> ("apple" "banana" "cherry")
z.str.split() {
  z.arg.named str $@ && local str=$REPLY
  z.arg.named delimiter $@ && local delimiter=${REPLY:-"|"}

  local IFS=$delimiter
  REPLY=(${=str})
}

# global substitute in a string
#
# $str: original string
# $search: search string
# $replace: replace string
# REPLY: modified string
# return: null
#
# example:
#  z.str.gsub str="Hello World" search="World" replace="Zsh" #=> "Hello Zsh"
z.str.gsub() {
  z.arg.named str $@ && local str=$REPLY
  z.arg.named search $@ && local search=$REPLY
  z.arg.named replace $@ && local replace=$REPLY

  if z.is_null $str || z.is_null $search; then
    z.return $str
  else
    z.return ${str//$search/$replace}
  fi
}
