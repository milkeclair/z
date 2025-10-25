typeset -a z_t_logs=()

# logs array management
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.logs  #=> ("log1" "log2" ...)
z.t._state.logs() {
  z.return ${z_t_logs[@]}
}

# add a log entry
#
# $1: log entry
# REPLY: null
# return: null
#
# example:
#  z.t._state.logs.add "This is a log entry"
z.t._state.logs.add() {
  z_t_logs+=($1)
}

# get a log entry by context
#
# $1: context index
# REPLY: null
# return: log entry
#
# example:
#  z.t._state.logs.context "0"  #=> "log entry at index 0"
z.t._state.logs.context() {
  local context=$1
  z.is_null $context && { z.return ""; return 0; }
  z.return ${z_t_logs[$context]:-""}
}

# set a log entry by context
#
# $1: context index
# $2: log entry
# REPLY: null
# return: null
#
# example:
#  z.t._state.logs.context.set "0" "Updated log entry"
z.t._state.logs.context.set() {
  local context=$1
  local value=$2

  local target_log=${z_t_logs[$context]}

  if z.is_not_null $target_log; then
    z_t_logs[$context]=$value
  fi
}
