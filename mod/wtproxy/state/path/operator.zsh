# 状態にworktreeパスが存在するか確認する
#
# $1: worktreeのパス
# REPLY: null
# return: 状態にパスが存在する場合は0、それ以外は1
#
# example:
#  z.wtproxy._state.path.has /path/to/worktree
z.wtproxy._state.path.has() {
  local target_path=$1
  local worktree_path

  for worktree_path in $z_wtproxy_state_paths; do
    z.is.eq "$worktree_path" "$target_path" && return 0
  done

  return 1
}
