# 作成者ごとのコミット統計を表示する
#
# $@: 統計から特定の拡張子やディレクトリを除くための任意の引数
# REPLY: null
# return: null
#
# example:
#   z.git.stats._author exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
z.git.stats() {
  z.io.line
  z.io "--- author stats ---"
  z.git.stats._show "$@"
}

# 作成者ごとのコミット統計を表示する
# 指定した拡張子とディレクトリを除く
#
# $exclude_exts?: 除外する拡張子の配列（例: "md" "txt"）
# $exclude_dirs?: 除外するディレクトリの配列（例: "docs" "tests"）
# REPLY: null
# return: null
#
# example:
#   z.git.stats._show exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
z.git.stats._show() {
  z.git.stats._exclude.exts $@ && local exclude_exts=($REPLY)
  z.git.stats._exclude.dirs $@ && local exclude_dirs=($REPLY)

  z.git.stats._exclude exclude_exts="${exclude_exts[*]}" exclude_dirs="${exclude_dirs[*]}"
  z.git.stats._author exclude_exts="${exclude_exts[*]}" exclude_dirs="${exclude_dirs[*]}"
}

# コミット統計で除外する拡張子とディレクトリを表示する
#
# $exclude_exts?: 除外する拡張子の配列（例: "md" "txt"）
# $exclude_dirs?: 除外するディレクトリの配列（例: "docs" "tests"）
# REPLY: null
# return: null
#
# example:
#   z.git.stats._exclude exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
z.git.stats._exclude() {
  z.arg.named exclude_exts $@ && local exclude_exts=($REPLY)
  z.arg.named exclude_dirs $@ && local exclude_dirs=($REPLY)

  z.io.line "exclude_exts: ${exclude_exts[*]}" "exclude_dirs: ${exclude_dirs[*]}"
  z.io.line
}

# 作成者ごとのコミット統計を表形式で表示する
#
# $exclude_exts?: 除外する拡張子の配列（例: "md" "txt"）
# $exclude_dirs?: 除外するディレクトリの配列（例: "docs" "tests"）
# REPLY: null
# return: null
#
# example:
#   z.git.stats._author exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
z.git.stats._author() {
  z.arg.named exclude_exts $@ && local exclude_exts=$REPLY
  z.arg.named exclude_dirs $@ && local exclude_dirs=$REPLY

  z.git.stats._author.header
  z.git.stats._author.body exclude_exts="$exclude_exts" exclude_dirs="$exclude_dirs"
  z.git.stats._author.footer
}
