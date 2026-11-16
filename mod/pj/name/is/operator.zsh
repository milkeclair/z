# プロジェクト名を登録ファイル名に使用できるか確認する
#
# $1: プロジェクト名
# REPLY: null
# return: 0|1
#
# example:
#  z.pj.name.is.valid some_project
z.pj.name.is.valid() {
  local pattern='^[A-Za-z0-9_][A-Za-z0-9_.-]*$'
  z.str.is.match "$1" "$pattern"
}
