# インデックスからworktreeポートキーを取得する
#
# $1: ポートのインデックス
# REPLY: worktreeポートキー
# return: null
#
# example:
#  z.wtproxy._port.worktree.key 1
#  # REPLY: "worktree_port_1"
z.wtproxy._port.worktree.key() {
  local port_index=$1

  REPLY="$z_wtproxy_worktree_port_key_prefix$port_index"
}

# worktreeポートキーからインデックスを取得する
#
# $1: worktreeポートキー
# REPLY: ポートのインデックス|null
# return: 連番のworktreeポートキーの場合は0、それ以外は1
#
# example:
#  z.wtproxy._port.worktree.index worktree_port_1
#  # REPLY: "1"
#  # return: 0
z.wtproxy._port.worktree.index() {
  local key=$1

  if z.str.is.match "$key" "^${z_wtproxy_worktree_port_key_prefix}[0-9]+$"; then
    z.str.remove.prefix "$key" "$z_wtproxy_worktree_port_key_prefix"
    return 0
  fi

  REPLY=""
  return 1
}
