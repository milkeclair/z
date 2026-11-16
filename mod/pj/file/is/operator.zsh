# 登録エントリがシンボリックリンクではなく通常ファイルか確認する
#
# $1: 登録ファイルのパス
# REPLY: null
# return: 0|1
#
# example:
#  z.pj.file.is.registration /tmp/config/z/pj/example
z.pj.file.is.registration() {
  z.file.exists "$1" && [[ ! -L $1 ]]
}
