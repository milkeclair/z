# fetch the selected distribution's mod directory into a work directory
#
# $dir: existing work directory
# $branch?: distribution branch (default: main)
# REPLY: extracted mod directory
# return: 0|1
#
# example:
#  z.install.mod.list._fetch dir=/tmp/mod-list branch=main
z.install.mod.list._fetch() {
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
