# upstream情報とともにGitの状態を表示する
#
# REPLY: null
# return: null
#
# example:
#  # upstreamがorigin/mainで2コミット先行し、modified_file.txtが未ステージの場合
#  z.git.status
#  # 出力: $'\'refs/remotes/origin/main\' by 2 commits.\n\n M modified_file.txt\n'
z.git.status() {
  local upstream=$(git rev-parse --symbolic-full-name @{u} 2>/dev/null)
  local ahead=$(git rev-list --count "${upstream}..HEAD" 2>/dev/null)

  if z.str.is.not.empty $upstream && z.int.is.not.zero $ahead; then
    z.io "'$upstream' by $ahead commits."
    z.io.line
  fi

	git status --short
}
