# get cached normalized docs for a z function
#
# $1: function name
# REPLY: normalized docs|null
# return: 0|1
#
# example:
#  z.completion.docs._get z.arg.get
z.completion.docs._get() {
  local function_name=$1

  if z.int.is.positive ${+z_completion_docs[$function_name]}; then
    z.return "${z_completion_docs[$function_name]}"
    return
  fi

  z.return
  return 1
}
