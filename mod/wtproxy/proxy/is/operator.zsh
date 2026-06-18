# check if proxy daemon is running
#
# REPLY: null
# return: 0 if daemon is running, otherwise 1
#
# example:
#  z.wtproxy._proxy.is.running
z.wtproxy._proxy.is.running() {
  z.wtproxy._config.value pid_file || return 1
  local pid_file=$REPLY

  z.file.not.exists $pid_file && return 1

  z.file.read path=$pid_file
  local pid=$REPLY

  z.wtproxy._proxy.is.pid "$pid"
}

# check if a pid belongs to wtproxy daemon
#
# $1: process id
# REPLY: null
# return: 0 if the process is wtproxy daemon, otherwise 1
#
# example:
#  z.wtproxy._proxy.is.pid 12345
z.wtproxy._proxy.is.pid() {
  local pid=$1

  z.is.null "$pid" && return 1
  z.io.null kill -0 "$pid" || return 1

  local command_line
  command_line=$(ps -p "$pid" -o command= 2>/dev/null) || return 1
  z.str.includes "$command_line" "z.wtproxy.start._serve"
}
