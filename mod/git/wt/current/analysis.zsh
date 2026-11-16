# 現在のGit worktreeのルートを取得する
#
# REPLY: worktreeルートの絶対パス
# return: ルートが見つかった場合は0、それ以外は1
#
# example:
#  # カレントディレクトリが/tmp/worktree内の場合
#  z.git.wt.current.root
#  # REPLY: "/tmp/worktree"
z.git.wt.current.root() {
  local worktree_path
  worktree_path=$(git rev-parse --show-toplevel)
  local exit_status=$?
  z.int.is.not.zero $exit_status && return 1

  REPLY="${worktree_path:A}"
}

# 現在のGit worktreeの共通Gitディレクトリを取得する
#
# REPLY: Gitの共通ディレクトリの絶対パス
# return: Gitの共通ディレクトリが見つかった場合は0、それ以外は1
#
# example:
#  # メインリポジトリのGitディレクトリが/tmp/repo/.gitの場合
#  z.git.wt.current.common_dir
#  # REPLY: "/tmp/repo/.git"
z.git.wt.current.common_dir() {
  local common_dir
  common_dir=$(git rev-parse --git-common-dir)
  local exit_status=$?
  z.int.is.not.zero $exit_status && return 1

  REPLY="${common_dir:A}"
}
