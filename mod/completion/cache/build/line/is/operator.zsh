# キャッシュのソース行がコメント行か確認する
#
# $1: ソース行
# REPLY: 先頭の空白を取り除いたソース行
# return: 0|1
#
# example:
#  z.completion.cache.build.line.is._comment "  # docs"
#  # REPLY: "# docs"
#  # return: 0
z.completion.cache.build.line.is._comment() {
  local line=$1
  z.str.gsub str="$line" search="^[[:space:]]+" replace=""
  local trimmed_line=$REPLY

  z.str.start_with "$trimmed_line" "#"
}
