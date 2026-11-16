# ファイルが存在するか確認する
#
# $1: ファイルのパス
# REPLY: null
# return: 0|1
#
# example:
#  z.file.exists "/path/to/file" #=> 0
z.file.exists() {
  local file=$1

  [[ -f $file ]]
}
