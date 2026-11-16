# 既存のプロジェクトディレクトリを、シンボリックリンクを解決した絶対パスにする
#
# $1: ディレクトリ。相対パスと先頭のチルダにも対応する
# REPLY: ディレクトリの絶対パス
# return: 0|1
#
# example:
#  # /tmp/exampleが実在し、シンボリックリンクでない場合
#  z.pj.add._directory /tmp/example
#  # REPLY: "/tmp/example"
#  # return: 0
z.pj.add._directory() {
  local dir=$1
  if z.is.eq "$dir" '~'; then
    dir=$HOME
  elif z.str.start_with "$dir" '~/'; then
    dir="$HOME/${dir#\~/}"
  fi

  if z.is.null "$dir" || z.str.includes "$dir" $'\n' || z.dir.not.exists "$dir"; then
    z.io.error "Project directory does not exist or is invalid: $dir"
    return 1
  fi

  z.str.start_with "$dir" / || dir="$PWD/$dir"
  z.path.real "$dir"
}
