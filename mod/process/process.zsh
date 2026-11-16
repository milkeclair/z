# send SIGTERM to processes selected by exactly one named argument
# name matches ps comm exactly; port selects TCP listeners and requires lsof
#
# $pid?: positive process ID
# $port?: TCP listening port
# $name?: exact process name
# REPLY: successfully signaled PIDs
# return: 0 if all selected PIDs were signaled, otherwise 1
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
