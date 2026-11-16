# ソースのメタデータから導入済みmodとその依存関係を解決する
#
# $source: ソースディレクトリ
# $@: ソース引数の後に続くmod名
# REPLY: 依存順に並べて重複を除いたmod名
# return: 0|1
#
# example:
#  z.update.mod._resolve source=/tmp/source completion
z.update.mod._resolve() {
  z.arg.named source "$@"
  local source_dir=$REPLY
  z.dir.exists "$source_dir" || { REPLY=""; return 1; }

  z.arg.named.shift source "$@"
  local requested=(${(@)REPLY})
  z.is.null "$requested" && REPLY="" && return 0

  local -A z_mod_names=()
  local -A z_mod_depends=()
  local z_mod_current=$requested[1]

  for recipe in "$source_dir"/mod/*/mod.zsh(N); do
    source "$recipe" || { REPLY=""; return 1; }
  done

  local resolved=()

  for requested_mod in "${requested[@]}"; do
    if z.mod.is.registered "$requested_mod"; then
      z.mod.dependencies.resolve "$requested_mod" || { REPLY=""; return 1; }
      resolved+=(${(@)REPLY})
    elif z.dir.exists "$source_dir/mod/$requested_mod"; then
      resolved+=("$requested_mod")
    else
      REPLY=""
      return 1
    fi
  done

  z.arr.unique "${resolved[@]}"
  local ordered=(${(@)REPLY})

  for dependency in "${ordered[@]}"; do
    z.dir.exists "$source_dir/mod/$dependency" || { REPLY=""; return 1; }
  done

  REPLY=("${ordered[@]}")
}
