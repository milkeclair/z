# worktreeパスに対応するエントリの連想配列を状態から組み立てる
#
# $1: worktreeのパス
# REPLY: エントリのキーと値の組
# return: null
#
# example:
#  z.wtproxy._state.entry /path/to/worktree
z.wtproxy._state.entry() {
  local worktree_path=$1

  local -A entry=(
    path $worktree_path
    branch $z_wtproxy_state_branch[$worktree_path]
    compose_project_name $z_wtproxy_state_compose[$worktree_path]
  )

  z.wtproxy._port.keys
  for port_key in ${(@)REPLY}; do
    z.wtproxy._state.port.get "$worktree_path" "$port_key"
    entry[$port_key]=$REPLY
  done

  z.hash.entries entry
}
