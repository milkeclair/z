# list available and installed mods from the selected distribution branch
# green: installed, orange: different contents, red: not installed
# local edits are also shown as update-available
#
# REPLY: null
# return: 0|1
#
# example:
#  z.install.mod.list
z.install.mod.list() {
  local work_dir=$(mktemp -d)
  z.dir.exists "$work_dir" || return 1

  {
    z.install.mod.list._fetch dir="$work_dir" branch="${Z_INSTALL_BRANCH:-main}" || return 1
    local source_dir=$REPLY

    local names=("$source_dir"/*(N/:t) "$z_root"/mod/*(N/:t))
    z.arr.unique "${names[@]}"
    z.arr.sort "${(@)REPLY}"
    local mod_names=(${(@)REPLY})

    for mod_name in "${mod_names[@]}"; do
      z.install.mod.list._status source="$source_dir/$mod_name" installed="$z_root/mod/$mod_name" || return 1
      local mod_state=$REPLY
      local color=green

      case $mod_state in
      update-available) color=orange ;;
      not-installed) color=red ;;
      esac

      z.io color="$color" "$mod_name [$mod_state]"
    done
  } always {
    z.dir.remove path="$work_dir" || return 1
  }

  z.return
}
