# ファイルが存在するか確認する
#
# $1: ファイルのパス
# REPLY: null
# return: 0|1
#
# example:
#  # /tmp/z-example.txtが存在する場合
#  z.file.exists "/tmp/z-example.txt"
#  # return: 0
z.file.exists() {
  local file=$1

  [[ -f $file ]]
}
