# format a test heading
#
# $1: indentation
# $2: color name
# $3: message
# REPLY: formatted heading
# return: null
#
# example:
#  z.t._log.format "  " green "My Test Suite"
z.t._log.format() {
  local indentation=$1
  local color_name=$2

  z.return "$3"
  local message="$indentation$REPLY"

  local code=""
  for code in ${(v)z_color_palette}; do
    message=${message//$code/}
  done

  local prefix=$z_color_palette[$color_name]
  if [[ -n "$prefix" ]]; then
    REPLY="$prefix$message$z_color_palette[reset]"
  else
    REPLY=$message
  fi
}
