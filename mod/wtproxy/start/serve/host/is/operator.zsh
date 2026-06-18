# check if a remote host is localhost
#
# $1: remote host
# REPLY: null
# return: 0 if host is localhost, otherwise 1
#
# example:
#  z.wtproxy.start._serve.host.is.localhost 127.0.0.1
z.wtproxy.start._serve.host.is.localhost() {
  local host=$1

  for localhost_host in $z_wtproxy_localhost_hosts; do
    z.is.eq $host $localhost_host && return 0
  done

  z.str.start_with "$host" "127."
}
