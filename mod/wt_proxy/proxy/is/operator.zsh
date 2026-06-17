# check if proxy daemon is running
#
# REPLY: null
# return: 0 if daemon is running, otherwise 1
#
# example:
#  z.wt_proxy._proxy.is.running
z.wt_proxy._proxy.is.running() {
  z.wt_proxy._config.value pid_file || return 1
  local pid_file=$REPLY

  z.file.not.exists $pid_file && return 1

  local pid=$(<$pid_file)

  z.wt_proxy._proxy.is.pid "$pid"
}

# check if a pid belongs to wt_proxy daemon
#
# $1: process id
# REPLY: null
# return: 0 if the process is wt_proxy daemon, otherwise 1
#
# example:
#  z.wt_proxy._proxy.is.pid 12345
z.wt_proxy._proxy.is.pid() {
  local pid=$1

  z.is.null "$pid" && return 1
  kill -0 "$pid" >/dev/null 2>&1 || return 1

  local command_line
  command_line=$(ps -p "$pid" -o command= 2>/dev/null) || return 1
  z.str.includes "$command_line" "z.wt_proxy.start._serve"
}
