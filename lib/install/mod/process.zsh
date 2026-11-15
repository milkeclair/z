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
    z.install.mod._fetch dir="$work_dir" branch="${Z_INSTALL_BRANCH:-main}" || return 1
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

# fetch the selected distribution's mod directory into a work directory
#
# $dir: existing work directory
# $branch?: distribution branch (default: main)
# REPLY: extracted mod directory
# return: 0|1
#
# example:
#  z.install.mod._fetch dir=/tmp/mod-list branch=main
z.install.mod._fetch() {
  z.arg.named dir "$@" && local dir=$REPLY
  z.arg.named branch "$@" default=main && local branch=$REPLY

  local archive="$dir/source.tar.gz"
  local url="https://github.com/milkeclair/z/archive/refs/heads/$branch.tar.gz"

  curl -fLsS "$url" -o "$archive" || return 1
  tar -xzf "$archive" -C "$dir" || return 1

  local roots=("$dir"/*(N/))
  if ! z.int.is.eq ${#roots} 1 || z.dir.not.exists "$roots[1]/mod"; then
    z.io.error "mod directory not found in the distribution"
    return 1
  fi

  z.return "$roots[1]/mod"
}
