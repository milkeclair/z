# display numbered registration names on standard error
#
# $@: project names in display order
# REPLY: null
# return: null
#
# example:
#  z.pj.remove._menu first second
z.pj.remove._menu() {
  local index=1
  local name
  for name in "$@"; do
    z.io "$index) $name" >&2
    ((index++))
  done
}

# select a registered project without modifying the registry
#
# REPLY: selected name, or empty when cancelled
# return: 0|1
#
# example:
#  z.pj.remove._select
z.pj.remove._select() {
  z.pj.file._names
  local names=("${(@)REPLY}")
  z.arr.count "${names[@]}"
  if z.int.is.zero $REPLY; then
    z.io "No projects registered." >&2
    z.return
    return 0
  fi

  z.pj.remove._menu "${names[@]}"
  z.io.oneline "Project number (empty to cancel): " >&2
  if ! z.io.read || z.is.null "$REPLY"; then
    z.return
    return 0
  fi

  local selection=$REPLY
  local index=1
  local name
  for name in "${names[@]}"; do
    if z.is.eq "$selection" "$index"; then
      REPLY=$name
      return 0
    fi
    ((index++))
  done
  z.io.error "Invalid project number: $selection"
  z.return
  return 1
}

# delete only the plain registration file for a validated name
#
# $1: project name
# REPLY: null
# return: 0|1
#
# example:
#  z.pj.remove._entry example
z.pj.remove._entry() {
  z.pj.file._path "$1" || return 1
  local file=$REPLY
  if ! z.pj.file.is.registration "$file"; then
    z.io.error "Project is not registered: $1"
    return 1
  fi

  rm -- "$file"
}
