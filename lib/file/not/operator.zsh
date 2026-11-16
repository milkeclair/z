# ファイルが存在しないか確認する
#
# $1: ファイルのパス
# REPLY: null
# return: 0|1
#
# example:
#  # /tmp/z-example.txtが存在する場合
#  z.file.not.exists "/tmp/z-example.txt"
#  # return: 1
z.file.not.exists() {
  ! z.file.exists $1
}
