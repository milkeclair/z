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
# $1: indent level (number of 2-space indents)
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.indent 2 "hello" "world" #=> "    hello world"
z.io.indent() {
  local indent_level=$1 && shift
  local indent=""

  for ((i=0; i<indent_level; i++)); do
    indent+="  "
  done

  print -- $indent$*
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

# printing provided arguments line by line to stderr
#
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.error.line "error1" "error2"
z.io.error.line() {
  # $@: print arguments
  # return: null
  print -u2 -l -- $@
}

# printing provided arguments with indentation to stderr
#
# $1: indent level (number of 2-space indents)
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.error.indent 2 "error message" #=> "    error message"
z.io.error.indent() {
  local indent_level=$1 && shift
  local indent=""

  for ((i=0; i<indent_level; i++)); do
    indent+="  "
  done

  z.io.error $indent$*
}
