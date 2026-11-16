# worktree用のDocker Composeプロジェクト名を組み立てる
#
# $1: ブランチのラベル
# REPLY: Composeのプロジェクト名
# return: 設定を取得できた場合は0、それ以外は1
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
  z.str.partition "$branch_hash" "[[:space:]]+"
  local -a hash_line=("${(@)REPLY}")
  branch_hash=$hash_line[1]

  local name="$config[project]_${branch_slug[1,42]}_${branch_hash[1,8]}"
  REPLY=${name[1,63]}
}
