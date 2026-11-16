# get accepted named argument names
#
# $1: name of the defaults hash
# REPLY: array of accepted argument names
# return: null
#
# example:
#  z.arg.parse._names values
z.arg.parse._names() {
  z.hash.keys $1 && local names=("${REPLY[@]}")
  local accepted_names=()
  local name

  for name in "${names[@]}"; do
    z.is.null "$name" && continue
    z.str.includes "$name" "=" && continue
    accepted_names+=("$name")
  done

  REPLY=("${accepted_names[@]}")
}
