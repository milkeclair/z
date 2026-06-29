# get normalized docs for a z function
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

  if z.is.true $z_completion_cache_ready; then
    return 1
  fi

  z.help._find_docs $function_name || return 1
  z.help._strip_comment_prefix "$REPLY"
  z.help._normalize_docs "$REPLY"
}
