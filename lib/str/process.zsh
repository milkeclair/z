typeset -gA z_color_palette=(
  [red]=$'\033[31m'
  [green]=$'\033[32m'
  [yellow]=$'\033[33m'
  [blue]=$'\033[34m'
  [magenta]=$'\033[35m'
  [cyan]=$'\033[36m'
  [white]=$'\033[37m'
  [reset]=$'\033[0m'
)

for color_file in ${z_root}/lib/str/color/*.zsh; do
  source $color_file
done

# get color code by name
#
# $1: color name
# REPLY: color code
# return: null
#
# example:
#  z.str.color red #=> "\033[31m"
z.str.color() {
  local selected=$1

  z.return ${z_color_palette[$selected]}
}

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
  z.arg.named delimiter default="|" $@ && local delimiter=$REPLY

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
