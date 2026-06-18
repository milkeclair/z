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
  local branch_hash=$(print -rn -- "$branch" | sha1sum)
  branch_hash=${branch_hash%% *}

  local hash_suffix=${branch_hash[1,8]}
  local max_name_length=63
  local separators_length=2
  local parts_length=$((max_name_length - separators_length - ${#hash_suffix}))
  local branch_part=${branch_slug[1,42]}
  local project_part=$config[project]

  if (( ${#project_part} + ${#branch_part} > parts_length )); then
    local branch_length=${#branch_part}
    if (( branch_length > parts_length )); then
      branch_length=$parts_length
    fi

    local project_length=$((parts_length - branch_length))
    project_part=${project_part[1,project_length]}
    branch_part=${branch_part[1,branch_length]}
  fi

  z.return "${project_part}_${branch_part}_${hash_suffix}"
}
