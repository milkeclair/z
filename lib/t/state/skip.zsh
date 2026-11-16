z_t_states[skip_describe]="false"
z_t_states[skip_context]="false"
z_t_states[skip_it]="false"

# describe階層のスキップ状態を取得する
#
# REPLY: true|false
# return: null
#
# example:
#  z.t._state.skip.describe.set false
#  z.t._state.skip.describe
#  # REPLY: "false"
z.t._state.skip.describe() {
  REPLY=${z_t_states[skip_describe]}
}

# describe階層のスキップ状態を設定する
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t._state.skip.describe.set true
#  z.t._state.skip.describe
#  # REPLY: "true"
z.t._state.skip.describe.set() {
  z_t_states[skip_describe]=$1
}

# context階層のスキップ状態を取得する
#
# REPLY: true|false
# return: null
#
# example:
#  z.t._state.skip.context.set false
#  z.t._state.skip.context
#  # REPLY: "false"
z.t._state.skip.context() {
  REPLY=${z_t_states[skip_context]}
}

# context階層のスキップ状態を設定する
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t._state.skip.context.set true
#  z.t._state.skip.context
#  # REPLY: "true"
z.t._state.skip.context.set() {
  z_t_states[skip_context]=$1
}

# it階層のスキップ状態を取得する
#
# REPLY: true|false
# return: null
#
# example:
#  z.t._state.skip.it.set false
#  z.t._state.skip.it
#  # REPLY: "false"
z.t._state.skip.it() {
  REPLY=${z_t_states[skip_it]}
}

# it階層のスキップ状態を設定する
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t._state.skip.it.set true
#  z.t._state.skip.it
#  # REPLY: "true"
z.t._state.skip.it.set() {
  z_t_states[skip_it]=$1
}
