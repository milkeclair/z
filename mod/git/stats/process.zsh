# 作成者ごとのコミット統計を表示する
#
# $@: 統計から特定の拡張子やディレクトリを除くための任意の引数
# REPLY: null
# return: null
#
# example:
#  # milkeclairのコミット2件、追加3行、削除1行が対象の場合
#  z.git.stats exclude_exts=md exclude_dirs=docs
#  # 表示例（一部、色と余白を省略）: │ milkeclair │ 2 │ 3 │ 1 │ 4 │
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
#  # milkeclairのコミット2件、追加3行、削除1行が対象の場合
#  z.git.stats._show exclude_exts=md exclude_dirs=docs
#  # 表示例（一部、色と余白を省略）: │ milkeclair │ 2 │ 3 │ 1 │ 4 │
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
#  z.git.stats._exclude exclude_exts=md exclude_dirs=docs
#  # 出力:
#  # exclude_exts: md
#  # exclude_dirs: docs
#  # （この後に空行）
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
#  # milkeclairのコミット2件、追加3行、削除1行が対象の場合
#  z.git.stats._author exclude_exts=md exclude_dirs=docs
#  # 表示例（一部、色と余白を省略）: │ milkeclair │ 2 │ 3 │ 1 │ 4 │
z.git.stats._author() {
  z.arg.named exclude_exts $@ && local exclude_exts=$REPLY
  z.arg.named exclude_dirs $@ && local exclude_dirs=$REPLY

  z.git.stats._author.header
  z.git.stats._author.body exclude_exts="$exclude_exts" exclude_dirs="$exclude_dirs"
  z.git.stats._author.footer
}
