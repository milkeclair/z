# build Docker Compose project name for a worktree
#
# $1: branch label
# REPLY: compose project name
# return: 0 if configuration is available, otherwise 1
#
# example:
#  z.wt_proxy._entry.compose.name feat/example
z.wt_proxy._entry.compose.name() {
  local branch=$1

  z.wt_proxy._config || return 1
  local -A config=("${(@)REPLY}")

  z.wt_proxy._slug $branch
  local branch_slug=$REPLY
  local branch_hash=$(print -rn -- "$branch" | sha1sum)
  branch_hash=${branch_hash%% *}

  local name="$config[project]_${branch_slug[1,42]}_${branch_hash[1,8]}"
  z.return ${name[1,63]}
}
