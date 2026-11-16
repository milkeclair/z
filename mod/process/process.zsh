# 名前付き引数で1つ指定した対象のプロセスへSIGTERMを送る
# 名前はps commに完全一致させる。ポート指定はTCP待受を対象とし、lsofが必要
#
# $pid?: 正のプロセスID
# $port?: TCP待受ポート
# $name?: 完全一致で照合するプロセス名
# REPLY: シグナルを送信できたPID
# return: 対象の全PIDへシグナルを送信できた場合は0、それ以外は1
#
# example:
#  z.process.kill pid=12345
#  z.process.kill port=3000
#  z.process.kill name=node
z.process.kill() {
  if ! z.process._pids "$@"; then
    REPLY=""
    return 1
  fi

  local pids=($REPLY)
  local sent=()
  local failed=0
  local pid

  for pid in "${pids[@]}"; do
    if kill -TERM -- "$pid"; then
      sent+=("$pid")
    else
      failed=1
    fi
  done

  REPLY=("${sent[@]}")
  return $failed
}
