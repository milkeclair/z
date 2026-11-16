# zのmodが登録済みか確認する
#
# $1: mod名
# REPLY: null
# return: 登録されている場合は0、それ以外は1
#
# example:
#  # git modを登録済みの場合
#  z.mod.is.registered git
#  # return: 0
z.mod.is.registered() {
  z.mod._store.ensure
  z.arg.first "$@"
  local mod_name=$REPLY

  z.is.true ${z_mod_names[$mod_name]:-false}
}
