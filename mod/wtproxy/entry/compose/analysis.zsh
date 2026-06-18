# build Docker Compose project name for a worktree
#
# $1: branch label
# REPLY: compose project name
# return: 0 if configuration is available, otherwise 1
#
# example:
#  z.wtproxy._entry.compose.name feat/example
z.wtproxy._entry.compose.name() {
  local branch=$1

  z.wtproxy._config || return 1
  local -A config=("${(@)REPLY}")

  z.wtproxy._slug $branch
  local branch_slug=$REPLY
  local branch_hash
  if (( $+commands[sha1sum] )); then
    branch_hash=$(print -rn -- "$branch" | sha1sum) || return 1
  elif (( $+commands[shasum] )); then
    branch_hash=$(print -rn -- "$branch" | shasum -a 1) || return 1
  else
    print -u2 "z.wtproxy._entry.compose.name: sha1sum or shasum is required"
    return 1
  fi
  branch_hash=${branch_hash%% *}

  local name="$config[project]_${branch_slug[1,42]}_${branch_hash[1,8]}"
  z.return ${name[1,63]}
}
