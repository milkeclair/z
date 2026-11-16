# コミット統計で除外する拡張子とディレクトリを決める
# 指定がなければ既定値（log、lock）を使う
#
# $exclude_exts?: 除外する拡張子の配列（例: "md" "txt"）
# REPLY: 除外する拡張子の配列
# return: null
#
# example:
#  z.git.stats._exclude.exts exclude_exts=md
#  # REPLY: ("md")
z.git.stats._exclude.exts() {
  z.arg.named exclude_exts $@ && local exts=($REPLY)
  if z.is.null $REPLY; then
    exts=(
      log
      lock
    )
  fi

  REPLY=("${exts[@]}")
}

# コミット統計で除外するディレクトリを決める
# 指定がなければ既定値（node_modules、dist）を使う
#
# $exclude_dirs?: 除外するディレクトリの配列（例: "docs" "tests"）
# REPLY: 除外するディレクトリの配列
# return: null
#
# example:
#  z.git.stats._exclude.dirs exclude_dirs=docs
#  # REPLY: ("docs")
z.git.stats._exclude.dirs() {
  z.arg.named exclude_dirs $@ && local dirs=($REPLY)
  if z.is.null $REPLY; then
    dirs=(
      node_modules
      dist
    )
  fi

  REPLY=("${dirs[@]}")
}
