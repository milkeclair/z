# ディレクトリが存在するか確認する
#
# $1: ディレクトリのパス
# REPLY: null
# return: 0|1
#
# example:
#  z.dir.exists "/path/to/dir" #=> return 0 if exists
z.dir.exists() {
  local dir=$1

  [[ -d $dir ]]
}
