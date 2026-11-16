# TCPポートが空いているか確認する
#
# $1: ポート番号
# REPLY: null
# return: ポートが空いている場合は0、それ以外は1
#
# example:
#  z.wtproxy._port.is.free 41080
z.wtproxy._port.is.free() {
  local port=$1

  zmodload zsh/net/tcp
  # 一時的にリッスンして確認する
  # 確認が取れたらcloseして準備
  z.io.null ztcp -l "$port"
  local exit_status=$?
  local fd=$REPLY
  if z.int.is.zero $exit_status; then
    z.io.null ztcp -c "$fd"
  fi

  return $exit_status
}

# ポートが使用済みポートに含まれるか確認する
#
# $1: ポート番号
# $@?: 使用済みポート
# REPLY: null
# return: ポートが使用中の場合は0、それ以外は1
#
# example:
#  z.wtproxy._port.is.used 41080 41080 41081
z.wtproxy._port.is.used() {
  local port=$1
  shift
  local used_port

  for used_port in "$@"; do
    z.is.eq $port $used_port && return 0
  done

  return 1
}
