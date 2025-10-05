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
#  z.str.color "red" #=> "\033[31m"
z.str.color() {
  local selected=$1

  z.return ${z_color_palette[$selected]}
}

# strip color codes from a string
#
# $1: string with color codes
# REPLY: string without color codes
# return: null
#
# example:
#  z.str.color.strip $'\033[31mHello\033[0m' #=> "Hello"
z.str.color.strip() {
  local message=$1

  local stripped=$message
  for code in ${(v)z_color_palette}; do
    stripped=${stripped//$code/}
  done

  z.return $stripped
}

# decorate a string with color codes
#
# $1: color name
# $2: string to decorate
# REPLY: decorated string
# return: null
#
# example:
#  z.str.color.decorate "red" "Hello" #=> $'\033[31mHello\033[0m'
z.str.color.decorate() {
  local color=$1
  local message=$2

  z.str.color.strip $message
  local plain=$REPLY

  z.str.color $color
  local color_prefix=$REPLY

  if z.is_not_null $color_prefix; then
    z.str.color reset
    local reset=$REPLY
    z.return "${color_prefix}${plain}${reset}"
  else
    z.return $plain
  fi
}

# decorate a string with red color
#
# $1: string to decorate
# REPLY: decorated string
# return: null
#
# example:
#  z.str.color.red "Hello" #=> $'\033[31mHello\033[0m'
z.str.color.red() {
  local message=$1

  z.str.color.decorate "red" $message
}

# decorate a string with green color
#
# $1: string to decorate
# REPLY: decorated string
# return: null
#
# example:
#  z.str.color.green "Hello" #=> $'\033[32mHello\033[0m'
z.str.color.green() {
  local message=$1

  z.str.color.decorate "green" $message
}

# decorate a string with yellow color
#
# $1: string to decorate
# REPLY: decorated string
# return: null
#
# example:
#  z.str.color.yellow "Hello" #=> $'\033[33mHello\033[0m'
z.str.color.yellow() {
  local message=$1

  z.str.color.decorate "yellow" $message
}

# decorate a string with blue color
#
# $1: string to decorate
# REPLY: decorated string
# return: null
#
# example:
#  z.str.color.blue "Hello" #=> $'\033[34mHello\033[0m'
z.str.color.blue() {
  local message=$1

  z.str.color.decorate "blue" $message
}

# decorate a string with magenta color
#
# $1: string to decorate
# REPLY: decorated string
# return: null
#
# example:
#  z.str.color.magenta "Hello" #=> $'\033[35mHello\033[0m'
z.str.color.magenta() {
  local message=$1

  z.str.color.decorate "magenta" $message
}

# decorate a string with cyan color
#
# $1: string to decorate
# REPLY: decorated string
# return: null
#
# example:
#  z.str.color.cyan "Hello" #=> $'\033[36mHello\033[0m'
z.str.color.cyan() {
  local message=$1

  z.str.color.decorate "cyan" $message
}

# decorate a string with white color
#
# $1: string to decorate
# REPLY: decorated string
# return: null
#
# example:
#  z.str.color.white "Hello" #=> $'\033[37mHello\033[0m'
z.str.color.white() {
  local message=$1

  z.str.color.decorate "white" $message
}
