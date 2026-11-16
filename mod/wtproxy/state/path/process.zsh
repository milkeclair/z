# 状態からworktreeパスを削除する
#
# $1: worktreeのパス
# REPLY: null
# return: null
#
# example:
#  # /tmp/worktreeだけが登録済みの場合
#  z.wtproxy._state.path.remove /tmp/worktree
#  # 変更後: z_wtproxy_state_paths=()
#  # 結果: そのパスのブランチ・Compose名・ポートの記録も消える
z.wtproxy._state.path.remove() {
  local target_path=$1
  local remaining=()
  local worktree_path

  for worktree_path in $z_wtproxy_state_paths; do
    z.is.eq "$worktree_path" "$target_path" || remaining+=($worktree_path)
  done

  z_wtproxy_state_paths=($remaining)
  unset "z_wtproxy_state_branch[$target_path]"
  unset "z_wtproxy_state_compose[$target_path]"
  z.wtproxy._state.port.unset_path "$target_path"

  z.is.eq "$z_wtproxy_state_active_path" "$target_path" && z_wtproxy_state_active_path=""
  return 0
}
