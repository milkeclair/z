# extract a function name from a cache source line
#
# $1: source line
# REPLY: function name|null
# return: 0|1
#
# example:
#  z.completion.cache.build.line._function_name "z.example() {"
z.completion.cache.build.line._function_name() {
  setopt local_options EXTENDED_GLOB

  local line=$1
  local trimmed_line=${line##[[:space:]]##}
  [[ "$trimmed_line" == z.*\(\)* ]] || return 1

  local function_name=${trimmed_line%%\(\)*}
  local declaration_suffix=${trimmed_line#"$function_name()"}
  declaration_suffix=${declaration_suffix##[[:space:]]##}
  z.is.eq "$declaration_suffix" "{" || return 1

  z.return "$function_name"
}
