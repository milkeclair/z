# convert a value to a Docker Compose friendly slug
#
# $1: source value
# REPLY: slug value
# return: null
#
# example:
#  z.wtproxy._slug "feat/WT Proxy!" #=> "feat_wtproxy"
z.wtproxy._slug() {
  local value=${1:-}

  setopt local_options extended_glob

  z.str.downcase "$value"
  value=$REPLY
  z.str.gsub str="$value" search="[^a-z0-9_-]" replace="_" pattern=true
  value=$REPLY
  value=${value##[^a-z0-9]##}
  value=${value%%[_-]##}
  z.is.null $value && value=$z_wtproxy_default_slug

  z.return $value
}
