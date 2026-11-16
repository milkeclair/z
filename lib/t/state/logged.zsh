z_t_states[logged]="false"

# ログが記録されているか確認する
#
# REPLY: null
# return: 0|1
#
# example:
#  if z.t._state.logged; then ...; fi
z.t._state.logged() {
  REPLY=${z_t_states[logged]}
}

# loggedの状態を設定する
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t._state.logged.set "true"
z.t._state.logged.set() {
  z_t_states[logged]=$1
}
