# build function name cache only
#
# REPLY: null
# return: null
#
# example:
#  z.completion.cache.build._names
z.completion.cache.build._names() {
  z_completion_function_names=()
  for function_name in ${(ko)functions}; do
    if z.str.start_with "$function_name" "z." && ! z.completion.function.is._private "$function_name"; then
      z_completion_function_names+=("$function_name")
    fi
  done
}

# build completion cache and write it to a job result file
#
# $result: result file path
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.cache.build._result result=/tmp/z/job/result
z.completion.cache.build._result() {
  z.arg.named result "$@" && local result=$REPLY
  z.is.null "$result" && return 1

  z.completion.cache._build
  z.completion.cache._dump
  local lines=("${(@f)REPLY}")
  z.file.write path="$result" content=""
  for line in "${lines[@]}"; do
    z.file.write.last path="$result" content="$line"
  done
}
