for success_file in ${z_root}/lib/io/success/*.zsh; do
  source $success_file
done

for warn_file in ${z_root}/lib/io/warn/*.zsh; do
  source $warn_file
done

for error_file in ${z_root}/lib/io/error/*.zsh; do
  source $error_file
done

# printing provided arguments
#
# $@: arguments
# $color?: color name
# $indent?: indent level
# REPLY: null
# return: null
#
# example:
#  z.io "hello" "world" #=> hello\nworld
z.io() {
  z.arg.named color $@ && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY
  local args=($REPLY)

  z.guard; {
    z.is_null $args && return
  }

  z.is_not_null $indent && z.str.indent level=$indent message="$args" && args=($REPLY)
  z.is_not_null $color && z.str.color.decorate color=$color message="$args" && args=($REPLY)

  print -- $args
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
# $color?: color name
# $indent?: indent level
# REPLY: null
# return: null
#
# example:
#  z.io.oneline "hello" "world" #=> hello world
#  z.io.oneline "hello"
#  z.io.oneline "world"         #=> helloworld
z.io.oneline() {
  z.arg.named color $@ && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY
  local args=($REPLY)

  z.guard; {
    z.is_null $args && return
  }

  z.is_not_null $indent && z.str.indent level=$indent message="$args" && args=($REPLY)
  z.is_not_null $color && z.str.color.decorate color=$color message="$args" && args=($REPLY)

  print -n -- $args
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
# $color?: color name
# $indent?: indent level
# REPLY: null
# return: null
#
# example:
#  z.io.line "hello" "world" #=> hello\nworld
z.io.line() {
  z.arg.named color $@ && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY
  local args=($REPLY)

  z.guard; {
    z.is_null $args && return
  }

  local lines=()
  for arg in $args; do
    local line=$arg

    z.is_not_null $indent && z.str.indent level=$indent message="$line" && line=$REPLY
    z.is_not_null $color && z.str.color.decorate color=$color message="$line" && line=$REPLY
    lines+=($line)
  done

  print -l -- $lines
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

# printing provided arguments with green color
#
# $@: arguments
# $color?: color name
# $indent?: indent level
# REPLY: null
# return: null
#
# example:
#  z.io.success "Operation completed successfully."
z.io.success() {
  z.arg.named color $@ default=green && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY

  z.io $REPLY color=$color indent=$indent
}

# printing provided arguments with yellow color
#
# $@: arguments
# $color?: color name
# $indent?: indent level
# REPLY: null
# return: null
#
# example:
#  z.io.warn "This is a warning message."
z.io.warn() {
  z.arg.named color $@ default=yellow && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY

  z.io $REPLY color=$color indent=$indent
}

# printing provided arguments to stderr
#
# $@: arguments
# $color?: color name
# $indent?: indent level
# REPLY: null
# return: null
#
# example:
#  z.io.error "error message"
z.io.error() {
  z.arg.named color $@ default=red && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY
  local args=($REPLY)

  z.guard; {
    z.is_null $args && return
  }

  z.is_not_null $indent && z.str.indent level=$indent message="$args" && args=($REPLY)
  z.is_not_null $color && z.str.color.decorate color=$color message="$args" && args=($REPLY)

  print -u2 -- $args
}
