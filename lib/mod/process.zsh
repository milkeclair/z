# zのmodを定義する
#
# $1: mod名
# REPLY: null
# return: null
#
# example:
#  z.mod git
#  # 変更後: z_mod_current="git"、z_mod_names[git]=true
z.mod() {
  z.mod._store.ensure
  z.arg.first "$@"
  local mod_name=$REPLY
  z.is.null "$mod_name" && return 1

  z_mod_current=$mod_name
  z_mod_names[$mod_name]=true
}

# 現在のz modに依存関係を追加する
#
# $@: 依存するmod名
# REPLY: null
# return: 現在のmodが存在する場合は0、それ以外は1
#
# example:
#  z.mod wtproxy; {
#    z.mod.depends git
#  }
#  z.mod.dependencies wtproxy
#  # REPLY: ("git")
z.mod.depends() {
  z.mod._store.ensure

  if z.is.null "$z_mod_current"; then
    z.io.error "current mod is not set"
    return 1
  fi

  z.mod.dependencies $z_mod_current
  local -a dependencies=(${(@)REPLY})
  dependencies+=("$@")
  z.arr.unique ${dependencies[@]}
  local -a unique_dependencies=(${(@)REPLY})

  z.arr.join ${unique_dependencies[@]}
  z_mod_depends[$z_mod_current]=$REPLY
}

# z modの定義をリセットする
#
# REPLY: null
# return: null
#
# example:
#  z.mod.reset
#  # 変更後: z_mod_names=()、z_mod_depends=()、z_mod_current=""
z.mod.reset() {
  typeset -gA z_mod_names=()
  typeset -gA z_mod_depends=()
  typeset -g z_mod_current=""
}
