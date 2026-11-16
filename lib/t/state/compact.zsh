z_t_states[compact]="${Z_TEST_COMPACT:-false}"

# compactの状態を取得する
#
# REPLY: null
# return: true|false
#
# example:
#  z.t._state.compact  #=> "false"
z.t._state.compact() {
  REPLY=${z_t_states[compact]}
}

# compactの状態を設定する
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t._state.compact.set "true"
z.t._state.compact.set() {
  z_t_states[compact]=$1
}
