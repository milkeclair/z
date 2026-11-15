# select a registered project name without modifying the registry
#
# REPLY: selected name, or empty when cancelled
# return: 0 for selection or cancellation, otherwise 1
#
# example:
#  z.pj.remove._select
z.pj.remove._select() {
  z.pj._names
  local -a names=("${REPLY[@]}")
  if [[ ${#names} -eq 0 ]]; then
    print -ru2 -- "No projects registered."
    z.return
    return 0
  fi

  local index=1
  local name
  for name in "${names[@]}"; do
    print -ru2 -- "$index) $name"
    ((index++))
  done
  print -nu2 -- "Project number (empty to cancel): "
  if ! z.io.read || [[ -z $REPLY ]]; then
    z.return
    return 0
  fi

  local selection=$REPLY
  index=1
  for name in "${names[@]}"; do
    if [[ $selection == "$index" ]]; then
      REPLY=$name
      return 0
    fi
    ((index++))
  done
  z.io.error "Invalid project number: $selection"
  z.return
  return 1
}
