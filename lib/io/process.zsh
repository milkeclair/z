for error_file in ${z_root}/lib/io/error/*.zsh; do
  source $error_file
done

# printing provided arguments
#
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io "hello" "world" #=> hello\nworld
z.io() {
  print -- $@
}

# printing empty line
#
# REPLY: null
# return: null
#
# example:
#  z.io.empty
z.io.empty() {
  print -- ""
}

# printing provided arguments in one line without newline at the end
#
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.oneline "hello" "world" #=> hello world
#  z.io.oneline "hello"
#  z.io.oneline "world"         #=> helloworld
z.io.oneline() {
  print -n -- $@
}

# clear the terminal screen
#
# REPLY: null
# return: null
#
# example:
#  z.io.clear
z.io.clear() {
  print "\033c"
}

# execute command and redirect both stdout and stderr to /dev/null
#
# $@: command and its arguments
# REPLY: null
# return: null
#
# example:
#  z.io.null ls -la
z.io.null() {
  z.arr.count $@
  if z.int.eq $REPLY 0; then
    cat >/dev/null 2>&1
  else
    "$@" >/dev/null 2>&1
  fi
}

# printing provided arguments line by line
#
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.line "hello" "world" #=> hello\nworld
z.io.line() {
  # $@: print arguments
  # return: null
  print -l -- $@
}

# printing provided arguments with indentation
#
# $level: indent level (number of 2-space indents)
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.indent level=2 "hello" "world" #=> "    hello world"
z.io.indent() {
  z.arg.named level $@ && local level=$REPLY
  z.arg.named.shift level $@
  local -a args=($REPLY)
  local indent=""

  for ((i=0; i<level; i++)); do
    indent+="  "
  done

  print -- "$indent${args[@]}"
}

# reading a line from standard input and storing it in REPLY
#
# REPLY: input line
# return: null
#
# example:
#  z.io.read #=> REPLY="input line"
z.io.read() {
  read -r REPLY
}

# printing provided arguments to stderr
#
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.error "error message"
z.io.error() {
  # $@: print arguments
  # return: null
  print -u2 -- $@
}

# printing provided arguments with color
#
# $1: color name
# $2: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.color red "Hello World" #=> (prints "Hello World" in red color)
z.io.color() {
  local color=$1
  shift

  z.is_null $1 && return 0

  z.str.color.decorate color=$color message="$*"
  z.io $REPLY
}
