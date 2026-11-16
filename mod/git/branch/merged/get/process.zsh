# 引数から除外ブランチを取得し、指定がなければ既定値を使う
#
# $exclude_branches?: 空白区切りの除外ブランチ名
# REPLY: 除外するブランチ名の配列
# return: null
#
# example:
#  z.git.branch._merged.get.excludes exclude_branches="main master feature/a"
#  # REPLY: ("main" "master" "feature/a")
z.git.branch._merged.get.excludes() {
  local exclude_branches=(main master develop release)

  z.arg.named exclude_branches "$@" && local exclude_arg=$REPLY
  if z.is.not.null "$exclude_arg"; then
    z.arr.split "$exclude_arg"
    exclude_branches=($REPLY)
  fi

  REPLY=("${exclude_branches[@]}")
}

# ブランチ名から"*"や"+"などの記号を取り除く
#
# $1: ブランチ名
# REPLY: 正規化したブランチ名
# return: null
#
# example:
#  z.git.branch._merged.get.remove_symbols "* feature/branch"
#  # REPLY: "feature/branch"
z.git.branch._merged.get.remove_symbols() {
  z.str.trim "$1" && local trimmed=$REPLY
  if z.str.start_with "$trimmed" "*" || z.str.start_with "$trimmed" "+"; then
    z.arr.split "$trimmed"
    REPLY=$REPLY[2]
  else
    REPLY="$trimmed"
  fi
}
