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
  z.arg.named level $@ && local level=$REPLY
  z.arg.named message $@ && local message=$REPLY

  if z.int.is.not.match $level || z.int.is.lt $level 0; then
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
  z.arg.named delimiter $@ default="|" && local delimiter=$REPLY

  local IFS=$delimiter
  REPLY=(${=str})
}

# match a string against a pattern
#
# $1: string
# $2: pattern (glob pattern)
# REPLY: matched substrings
# return: null
#
# example:
#  z.str.match "helloWorld" "[a-z]*" #=> ("hello")
z.str.match() {
  local str=$1
  local pattern=$2

  z.return ${(MS)str##${~pattern}}
}

# global substitute in a string
#
# $str: original string
# $search: search string or pattern
# $replace: replace string
# $pattern?: if set, treat search as a glob pattern (default: false)
# REPLY: modified string
# return: null
#
# example:
#  z.str.gsub str="Hello World" search="World" replace="Zsh" #=> "Hello Zsh"
#  z.str.gsub str="Hello123World" search="[0-9]" replace="-" pattern=true #=> "Hello---World"
#  z.str.gsub str="helloWorld" search="[A-Z]" replace='_$MATCH' pattern=true #=> "hello_World"
z.str.gsub() {
  z.arg.named str $@ && local str=$REPLY
  z.arg.named search $@ && local search=$REPLY
  z.arg.named replace $@ && local replace=$REPLY
  z.arg.named pattern $@ default=false && local pattern=$REPLY

  if z.is.null $str || z.is.null $search; then
    z.return $str
  elif z.is.true $pattern; then
    setopt local_options EXTENDED_GLOB
    z.return ${str//(#m)${~search}/${(e)replace}}
  else
    z.return ${str//$search/$replace}
  fi
}

# convert string to uppercase
#
# $1: original string
# REPLY: uppercase string
# return: null
#
# example:
#  z.str.upcase "hello" #=> "HELLO"
z.str.upcase() {
  local str=$1

  z.return ${(U)str}
}

# convert string to lowercase
#
# $1: original string
# REPLY: lowercase string
# return: null
#
# example:
#  z.str.downcase "HELLO" #=> "hello"
z.str.downcase() {
  local str=$1

  z.return ${(L)str}
}

# convert string to camelCase
#
# $1: original string
# REPLY: camelCase string
# return: null
#
# example:
#  z.str.camelize "hello_world" #=> "helloWorld"
z.str.camelize() {
  local str=$1
  local result=""
  local capitalize_next=false

  z.group "downcase if delimiters exist"; {
    if z.str.is.match "$str" "*[ _-]*"; then
      z.str.downcase "$str"
      str=$REPLY
    fi
  }

  for (( i=1; i<=${#str}; i++ )); do
    local char=${str[i]}

    if z.str.is.match $char "[ _-]"; then
      capitalize_next=true
    elif $capitalize_next; then
      result+=${(U)char}
      capitalize_next=false
    else
      result+=$char
    fi
  done

  z.return ${(L)result[1]}${result[2,-1]}
}

# convert string to PascalCase
#
# $1: original string
# REPLY: PascalCase string
# return: null
#
# example:
#  z.str.pascalize "hello_world" #=> "HelloWorld"
z.str.pascalize() {
  local str=$1
  local result=""
  local capitalize_next=true

  z.group "downcase if delimiters exist"; {
    if z.str.is.match "$str" "*[ _-]*"; then
      z.str.downcase "$str"
      str=$REPLY
    fi
  }

  for (( i=1; i<=${#str}; i++ )); do
    local char=${str[i]}

    if z.str.is.match $char "[ _-]"; then
      capitalize_next=true
    elif $capitalize_next; then
      result+=${(U)char}
      capitalize_next=false
    else
      result+=$char
    fi
  done

  z.return $result
}

# convert string to CONSTANTIZE format
#
# $1: original string
# REPLY: CONSTANTIZE string
# return: null
#
# example:
#  z.str.constantize "helloWorld" #=> "HELLO_WORLD"
z.str.constantize() {
  local str=$1
  local result=""
  local previous_char=""

  z.str.upcase $str
  str=$REPLY

  for (( i=1; i<=${#str}; i++ )); do
    local char=${str[i]}

    if z.str.is.match $char "[ _-]"; then
      if [[ $previous_char != "_" ]]; then
        result+="_"
        previous_char="_"
      fi
    else
      previous_char=$char
      result+=$char
    fi
  done

  z.return $result
}

# convert string to underscore_case
#
# $1: original string
# REPLY: underscore_case string
# return: null
#
# example:
#  z.str.underscore "helloWorld" #=> "hello_world"
z.str.underscore() {
  local str=$1

  z.str.delimitize $str delimiter="_" replace_chars="[ -]"
}

# convert string to kebab-case
#
# $1: original string
# REPLY: kebab-case string
# return: null
#
# example:
#  z.str.kebabize "helloWorld" #=> "hello-world"
z.str.kebabize() {
  local str=$1

  z.str.delimitize $str delimiter="-" replace_chars="[ _]"
}

# convert string by inserting delimiters
#
# $delimiter: delimiter to insert
# $replace_chars: characters to replace with delimiter (default: "[ _-]")
# $1: original string
# REPLY: converted string
# return: null
#
# example:
#  z.str.delimitize delimiter="_" "helloWorld" #=> "hello_world"
#  z.str.delimitize delimiter="-" replace_chars="[ _]" "hello world_test" #=> "hello-world-test"
z.str.delimitize() {
  z.arg.named delimiter $@ && local delimiter=$REPLY
  z.arg.named replace_chars $@ default="[ _-]" && local replace_chars=$REPLY
  z.arg.named.shift delimiter $@
  z.arg.named.shift replace_chars $REPLY

  local str=$REPLY
  local result=""

  z.group "downcase if delimiters exist"; {
    if z.str.is.match "$str" "*[ _-]*"; then
      z.str.downcase "$str"
      str=$REPLY
    fi
  }

  # insert delimiter before uppercase letters
  # e.g., "helloWorld" -> "hello_World" (if delimiter is "_")
  z.str.gsub str="$str" search="[A-Z]" replace='${delimiter}${MATCH}' pattern=true
  result=${(L)REPLY}

  # replace specified characters with delimiter
  # e.g., "hello world-test" -> "hello_world_test" (if delimiter is "_", replace_chars is "[ -]")
  z.str.gsub str="$result" search="$replace_chars" replace="${delimiter}" pattern=true
  result=$REPLY

  # remove consecutive delimiters
  # e.g., "hello__world" -> "hello_world" (if delimiter is "_")
  while z.str.is.match "$result" "*${delimiter}${delimiter}*"; do
    z.str.gsub str="$result" search="${delimiter}${delimiter}" replace="${delimiter}"
    result=$REPLY
  done

  # remove leading delimiter
  # e.g., "_hello_world" -> "hello_world" (if delimiter is "_")
  result=${result#${delimiter}}

  z.return ${(L)result}
}

# make string visible (escape non-printable characters)
#
# $1: original string
# REPLY: visible string
# return: null
#
# example:
#  z.str.visible $'\nHello\tWorld' #=> '\nHello\tWorld'
z.str.visible() {
  local str=$1

  z.return ${(V)str}
}

# left-justify a string with specified width and fill character
#
# $width: total width of the resulting string
# $fill?: fill character (default: space)
# $1: original string
# REPLY: left-justified string
# return: null
#
# example:
#  z.str.ljust width=10 fill="." "Hi" #=> "Hi........"
z.str.ljust() {
  z.arg.named width $@ && local width=$REPLY
  z.arg.named fill $@ default=" " && local fill=$REPLY
  z.arg.named.shift width $@
  z.arg.named.shift fill $REPLY
  local str=$REPLY

  local str_length=${#str}
  if z.int.is.gteq $str_length $width; then
    z.return $str
    return
  fi

  local padding_length=$((width - str_length))
  local padding=""
  for (( i=0; i<padding_length; i++ )); do
    padding+=$fill
  done

  z.return "${str}${padding}"
}

# right-justify a string with specified width and fill character
#
# $width: total width of the resulting string
# $fill?: fill character (default: space)
# $1: original string
# REPLY: right-justified string
# return: null
#
# example:
#  z.str.rjust width=10 fill="." "Hi" #=> "........Hi"
z.str.rjust() {
  z.arg.named width $@ && local width=$REPLY
  z.arg.named fill $@ default=" " && local fill=$REPLY
  z.arg.named.shift width $@
  z.arg.named.shift fill $REPLY
  local str=$REPLY

  local str_length=${#str}
  if z.int.is.gteq $str_length $width; then
    z.return $str
    return
  fi

  local padding_length=$((width - str_length))
  local padding=""
  for (( i=0; i<padding_length; i++ )); do
    padding+=$fill
  done

  z.return "${padding}${str}"
}
