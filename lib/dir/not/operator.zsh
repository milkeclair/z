# ディレクトリが存在しないか確認する
#
# $1: ディレクトリのパス
# REPLY: null
# return: 0|1
#
# example:
#  # /tmp/z-example-dirが存在しない場合
#  z.dir.not.exists "/tmp/z-example-dir"
#  # return: 0
z.dir.not.exists() {
  local dir=$1

  ! z.dir.exists $dir
}
