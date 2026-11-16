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
#  # この例で起動した子プロセスだけを終了する
#  sleep 30 &
#  local target_pid=$!
#  z.process.kill pid=$target_pid
#  # target_pidが12345だった場合のREPLY: ("12345")
#  # return: 0
#  # 自然終了を待たずTERMで停止する
#  wait "$target_pid" 2>/dev/null
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
