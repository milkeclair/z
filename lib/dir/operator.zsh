# ディレクトリが存在するか確認する
#
# $1: ディレクトリのパス
# REPLY: null
# return: 0|1
#
# example:
#  # /tmp/z-example-dirが存在する場合
#  z.dir.exists "/tmp/z-example-dir"
#  # return: 0
z.dir.exists() {
  local dir=$1

  [[ -d $dir ]]
}
