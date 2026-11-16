# worktreeポートの複合状態キーを取得する
#
# $1: worktreeのパス
# $2: ポートキー
# REPLY: 複合状態キー
# return: null
#
# example:
#  z.wtproxy._state.port.state_key /path/to/worktree worktree_port_1
z.wtproxy._state.port.state_key() {
  local worktree_path=$1
  local port_key=$2

  REPLY="${worktree_path}|${port_key}"
}

# 保存済みのworktreeポートを取得する
#
# $1: worktreeのパス
# $2: ポートキー
# REPLY: 保存したポート|null
# return: null
#
# example:
#  z.wtproxy._state.port.get /path/to/worktree worktree_port_1
z.wtproxy._state.port.get() {
  local worktree_path=$1
  local port_key=$2

  z.wtproxy._state.port.state_key "$worktree_path" "$port_key"
  local state_key=$REPLY

  REPLY=$z_wtproxy_state_port[$state_key]
}
