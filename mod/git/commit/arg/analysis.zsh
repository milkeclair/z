# extract commit args
# results has hash keys, receiver can build an hash from it
#
# $@: commit args
# REPLY: array of commit options
# return: null
#
# example:
#   z.git.commit.arg.extract.opts -m "commit message" --amend
#   #=> (tag "feat" message "commit message" ticket "TICKET-123" opts_count 2 opts_1 "-m" opts_2 "--amend")
#   local -A results=(${(@)REPLY})
z.git.commit.arg.extract() {
  local tag=$1
  local message=$2
  local ticket=""
  local opts=()
  shift 2

  for arg in $@; do
    if z.str.is.match $arg -*; then
      opts+=($arg)
    elif z.is.null $ticket; then
      ticket=$arg
    fi
  done

  local result=(
    tag "$tag"
    message "$message"
    ticket "$ticket"
    opts_count "${#opts[@]}"
  )

  local idx=1
  for opt in ${opts[@]}; do
    result+=(opts_$idx "$opt")
    ((idx++))
  done

  z.return keep_empty=true "${result[@]}"
}
