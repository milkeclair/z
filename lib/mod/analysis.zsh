# z modが直接依存するmodを取得する
#
# $1: mod名
# REPLY: 依存するmod名
# return: null
#
# example:
#  z.mod.dependencies wtproxy
z.mod.dependencies() {
  z.mod._store.ensure
  z.arg.first "$@"
  local mod_name=$REPLY

  REPLY=("${=z_mod_depends[$mod_name]}")
}
