# check if a TCP port is free
#
# $1: port number
# REPLY: null
# return: 0 if port is free, otherwise 1
#
# example:
#  z.wt_proxy._port.is.free 41080
z.wt_proxy._port.is.free() {
  local port=$1

  zmodload zsh/net/tcp
  # 一時的にリッスンして確認する
  # 確認が取れたらcloseして準備
  ztcp -l "$port" >/dev/null 2>&1
  local exit_status=$?
  local fd=$REPLY
  if z.int.is.zero $exit_status; then
    ztcp -c "$fd" >/dev/null 2>&1
  fi

  return $exit_status
}

# check if a port is included in used ports
#
# $1: port number
# $@?: used ports
# REPLY: null
# return: 0 if port is used, otherwise 1
#
# example:
#  z.wt_proxy._port.is.used 41080 41080 41081
z.wt_proxy._port.is.used() {
  local port=$1
  shift
  local used_port

  for used_port in "$@"; do
    z.is.eq $port $used_port && return 0
  done

  return 1
}
