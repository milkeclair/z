# 現在のブランチのラベルを取得する
#
# REPLY: ブランチ名、またはdetached-<短いHEAD>
# return: ラベルが見つかった場合は0、それ以外は1
#
# example:
#  z.git.branch.label.current #=> "main"
z.git.branch.label.current() {
  local branch
  branch=$(git branch --show-current)
  local exit_status=$?
  z.int.is.not.zero $exit_status && return 1

  if z.is.not.null $branch; then
    REPLY=$branch
    return
  fi

  local head
  head=$(git rev-parse --short HEAD)
  exit_status=$?
  z.int.is.not.zero $exit_status && return 1

  REPLY="detached-$head"
}

# パスに対応するブランチのラベルを取得する
#
# $1: Git worktreeのパス
# REPLY: ブランチ名、またはdetached-<短いHEAD>
# return: ラベルが見つかった場合は0、それ以外は1
#
# example:
#  z.git.branch.label.for /path/to/worktree #=> "main"
z.git.branch.label.for() {
  local worktree_path=$1
  local branch
  branch=$(git -C "$worktree_path" branch --show-current)
  local exit_status=$?
  z.int.is.not.zero $exit_status && return 1

  if z.is.not.null $branch; then
    REPLY=$branch
    return
  fi

  local head
  head=$(git -C "$worktree_path" rev-parse --short HEAD)
  exit_status=$?
  z.int.is.not.zero $exit_status && return 1

  REPLY="detached-$head"
}
