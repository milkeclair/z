# 現在のブランチの最新の変更をpushする
# 現在のブランチがpr/123なら、そのPRの最新の変更をpushする
# 引数に"origin"があれば、その引数でpushする
#
# REPLY: null
# return: null
#
# example:
#  # mainブランチからorigin/mainへのpushに成功した場合
#  z.git.push
#  # 出力の先頭: Pushing latest changes for current branch main
#  # return: 0
z.git.push() {
  if z.git._hp.arg.has.origin "$@"; then
    git push "$@"
    return 0
  fi

  z.git.push._pr || z.git.push._current
}

# PRブランチの最新の変更をpushする
#
# REPLY: null
# return: null
#
# example:
#  # ブランチがpr/123で、PR #123のheadがfeature/exampleの場合
#  # originへのpushに成功することが前提
#  z.git.push._pr
#  # 出力の先頭: Pushing latest changes for PR #123
#  # return: 0
z.git.push._pr() {
  z.git.branch.current._get
  local current_branch=$REPLY

  z.str.match.rest "$current_branch" "pr/"
  local pr_number=$REPLY

  if z.str.is.not.empty "$pr_number" && z.int.is.match "$pr_number"; then
    local head_ref=$(gh pr view "$pr_number" --json headRefName --jq .headRefName)

    if z.str.is.empty "$head_ref"; then
      z.io.error "Could not resolve head branch for PR #${pr_number}"
      return 1
    fi

    z.io "Pushing latest changes for PR #${pr_number}"
    z.io.empty
    git push --set-upstream origin "HEAD:${head_ref}"
    return 0
  else
    return 1
  fi
}

# 現在のブランチの最新の変更をpushする
#
# REPLY: null
# return: null
#
# example:
#  # mainブランチからorigin/mainへのpushに成功した場合
#  z.git.push._current
#  # 出力の先頭: Pushing latest changes for current branch main
#  # return: 0
z.git.push._current() {
  z.git.branch.current._get
  local current_branch=$REPLY

  z.io "Pushing latest changes for current branch $current_branch"
  z.io.empty
  git push --set-upstream origin "$current_branch"
}
