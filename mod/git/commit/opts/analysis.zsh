# extract commit options
#
# $@: commit args
# REPLY: array of valid commit options
# return: null
#
# example:
#   z.git.commit.opts.extract -m "commit message" -ca -ae
#   #=> ("--amend" "--allow-empty")
z.git.commit.opts.extract() {
  local opts=()
  local valid_opts=()

  for arg in "$@"; do
    if z.str.is.match "$arg" "-*"; then
      opts+=($arg)
    fi
  done

  for opt in ${opts[@]}; do
    if z.is.eq $opt -ca; then
      valid_opts+=(--amend)
    elif z.is.eq $opt -ae; then
      valid_opts+=(--allow-empty)
    fi
  done

  z.return $valid_opts
}
