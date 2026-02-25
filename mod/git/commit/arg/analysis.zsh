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
    tag $tag
    message $message
    ticket $ticket
    opts_count ${#opts[@]}
  )

  local idx=1
  for opt in ${opts[@]}; do
    result+=(opts_$idx $opt)
    ((idx++))
  done

  z.return keep_empty=true $result
}
