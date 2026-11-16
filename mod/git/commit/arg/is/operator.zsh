# コミット作成に必要な引数が揃っているか確認する
# それ以外はヘルプを表示する
#
# $@: コミット引数
# REPLY: null
# return: 0|1
#
# example:
#  z.git.commit._arg.is.enough feat "add new feature"
#  # return: 0
z.git.commit._arg.is.enough() {
  local tag_and_message=2

  z.arr.count $@
  if z.int.is.lt $REPLY $tag_and_message; then
    z.io.line
    z.git.commit.help
    return 1
  fi
}
