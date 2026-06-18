# stop proxy daemon for z.wtproxy.stop
#
# REPLY: null
# return: 0 if daemon is stopped, otherwise 1
#
# example:
#  z.wtproxy.stop._daemon
z.wtproxy.stop._daemon() {
  z.wtproxy._config.value pid_file || return 1
  local pid_file=$REPLY

  z.file.not.exists $pid_file && return 1

  local pid=$(<$pid_file)
  z.wtproxy._proxy.is.pid "$pid" || return 1

  kill -TERM "$pid" >/dev/null 2>&1 || return 1
  sleep 0.2
  return 0
}
