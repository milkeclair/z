# 登録エントリがシンボリックリンクではなく通常ファイルか確認する
#
# $1: 登録ファイルのパス
# REPLY: null
# return: 0|1
#
# example:
#  # 指定先が通常の登録ファイルの場合
#  z.pj.file.is.registration /tmp/config/z/pj/example
#  # return: 0
z.pj.file.is.registration() {
  z.file.exists "$1" && [[ ! -L $1 ]]
}
