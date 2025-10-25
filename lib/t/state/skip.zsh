z_t_states[skip_describe]="false"
z_t_states[skip_context]="false"
z_t_states[skip_it]="false"

# get the skip state for describe level
#
# REPLY: null
# return: true|false
#
# example:
#  z.t._state.skip.describe  #=> "false"
z.t._state.skip.describe() {
  z.return ${z_t_states[skip_describe]}
}

# set the skip state for describe level
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t._state.skip.describe.set "true"
z.t._state.skip.describe.set() {
  z_t_states[skip_describe]=$1
}

# get the skip state for context level
#
# REPLY: null
# return: true|false
#
# example:
#  z.t._state.skip.context  #=> "false"
z.t._state.skip.context() {
  z.return ${z_t_states[skip_context]}
}

# set the skip state for context level
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t._state.skip.context.set "true"
z.t._state.skip.context.set() {
  z_t_states[skip_context]=$1
}

# get the skip state for it level
#
# REPLY: null
# return: true|false
#
# example:
#  z.t._state.skip.it  #=> "false"
z.t._state.skip.it() {
  z.return ${z_t_states[skip_it]}
}

# set the skip state for it level
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t._state.skip.it.set "true"
z.t._state.skip.it.set() {
  z_t_states[skip_it]=$1
}
