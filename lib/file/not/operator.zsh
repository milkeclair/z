# ファイルが存在しないか確認する
#
# $1: ファイルのパス
# REPLY: null
# return: 0|1
#
# example:
#  z.file.not.exists "/path/to/file" #=> 1
z.file.not.exists() {
  ! z.file.exists $1
}
