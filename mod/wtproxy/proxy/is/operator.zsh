# プロキシデーモンが動作中か確認する
#
# REPLY: null
# return: デーモンが動作中の場合は0、それ以外は1
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

# PIDがwtproxyデーモンのものか確認する
#
# $1: プロセスID
# REPLY: null
# return: wtproxyデーモンのプロセスの場合は0、それ以外は1
#
# example:
#  z.wtproxy._proxy.is.pid 12345
z.wtproxy._proxy.is.pid() {
  local pid=$1

  z.is.null "$pid" && return 1
  z.io.null kill -0 "$pid" || return 1

  local command_line=$(ps -p "$pid" -o command= 2>/dev/null)
  z.str.includes "$command_line" "z.wtproxy.start._serve"
}
