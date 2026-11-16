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
#  z.kill pid=12345
#  z.kill port=3000
#  z.kill name=node
z.kill() {
  if ! z.kill._pids "$@"; then
    z.return
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

  z.return "${sent[@]}"
  return $failed
}
