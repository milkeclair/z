# z.wtproxy.stop用のプロキシデーモンを停止する
#
# REPLY: null
# return: デーモンを停止できた場合は0、それ以外は1
#
# example:
#  # PIDファイルが正しいデーモンを指し、TERM送信に成功する場合
#  z.wtproxy.stop._daemon
#  # return: 0
z.wtproxy.stop._daemon() {
  z.wtproxy._config.value pid_file || return 1
  local pid_file=$REPLY

  z.file.not.exists $pid_file && return 1

  z.file.read path=$pid_file
  local pid=$REPLY
  z.wtproxy._proxy.is.pid "$pid" || return 1

  z.io.null kill -TERM "$pid" || return 1
  sleep 0.2
  return 0
}
