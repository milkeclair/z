z_t_states[all_log]="${Z_TEST_ALL_LOG:-false}"

# all_logの状態を取得する
#
# REPLY: null
# return: true|false
#
# example:
#  z.t._state.all_log  #=> "true"
z.t._state.all_log() {
  REPLY=${z_t_states[all_log]}
}

# all_logの状態を設定する
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t._state.all_log.set "true"
z.t._state.all_log.set() {
  z_t_states[all_log]=$1
}
