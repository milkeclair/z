# リモートホストがlocalhostか確認する
#
# $1: リモートホスト
# REPLY: null
# return: ホストがlocalhostの場合は0、それ以外は1
#
# example:
#  z.wtproxy.start._serve.host.is.localhost 127.0.0.1
#  # return: 0
#  z.wtproxy.start._serve.host.is.localhost 192.0.2.1
#  # return: 1
z.wtproxy.start._serve.host.is.localhost() {
  local host=$1

  for localhost_host in $z_wtproxy_localhost_hosts; do
    z.is.eq $host $localhost_host && return 0
  done

  z.str.start_with "$host" "127."
}
