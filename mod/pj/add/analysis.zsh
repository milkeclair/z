# resolve an existing project directory to its absolute physical path
#
# $1: directory, including a relative path or a leading tilde
# REPLY: absolute directory path
# return: 0|1
#
# example:
#  z.pj.add._directory ~/repo/example
z.pj.add._directory() {
  local dir=$1
  if z.is.eq "$dir" '~'; then
    dir=$HOME
  elif z.str.start_with "$dir" '~/'; then
    dir="$HOME/${dir#\~/}"
  fi

  if z.is.null "$dir" || z.str.includes "$dir" $'\n' || z.dir.not.exists "$dir"; then
    z.io.error "Project directory does not exist or is invalid: $dir"
    return 1
  fi

  z.str.start_with "$dir" / || dir="$PWD/$dir"
  z.path.real "$dir"
}
