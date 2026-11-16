z_t_states[failed_only]="${Z_TEST_FAILED_ONLY:-false}"

# failed_onlyの状態を取得する
#
# REPLY: true|false
# return: null
#
# example:
#  z.t._state.failed_only.set false
#  z.t._state.failed_only
#  # REPLY: "false"
z.t._state.failed_only() {
  REPLY=${z_t_states[failed_only]}
}

# failed_onlyの状態を設定する
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t._state.failed_only.set true
#  z.t._state.failed_only
#  # REPLY: "true"
z.t._state.failed_only.set() {
  z_t_states[failed_only]=$1
}
