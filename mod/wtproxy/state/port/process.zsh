# worktreeポートを保存する
#
# $1: worktreeのパス
# $2: ポートキー
# $3: ポート
# REPLY: null
# return: null
#
# example:
#  z.wtproxy._state.init
#  z.wtproxy._state.port.set /tmp/worktree worktree_port_1 3001
#  z.wtproxy._state.port.get /tmp/worktree worktree_port_1
#  # REPLY: "3001"
z.wtproxy._state.port.set() {
  local worktree_path=$1
  local port_key=$2
  local port=$3

  z.wtproxy._state.port.state_key "$worktree_path" "$port_key"
  local state_key=$REPLY

  z_wtproxy_state_port[$state_key]=$port
}

# worktreeパスに保存したポートを削除する
#
# $1: worktreeのパス
# REPLY: null
# return: null
#
# example:
#  z.wtproxy._state.init
#  z.wtproxy._state.port.set /tmp/worktree worktree_port_1 3001
#  z.wtproxy._state.port.unset_path /tmp/worktree
#  z.wtproxy._state.port.get /tmp/worktree worktree_port_1
#  # REPLY: ""
z.wtproxy._state.port.unset_path() {
  local worktree_path=$1
  local state_key

  z.hash.keys z_wtproxy_state_port
  for state_key in ${(@)REPLY}; do
    z.str.start_with "$state_key" "$worktree_path|" && unset "z_wtproxy_state_port[$state_key]"
  done
}
