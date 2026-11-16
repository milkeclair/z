# resolve one process selector to distinct positive PIDs
#
# $pid?: process ID (1..2147483647)
# $port?: TCP listening port (1..65535; requires lsof)
# $name?: exact process name from ps comm (requires ps)
# REPLY: matching PIDs on success
# return: 0 if resolved, otherwise 1
#
# example:
#  z.process._pids port=3000
z.process._pids() {
  if ! z.int.is.eq $# 1; then
    z.io.error "Specify exactly one of pid=, port=, or name="
    return 1
  fi

  case $1 in
  pid=*)
    z.arg.named.literal pid "$@" && local pid=$REPLY
    local pids=("$pid")
    ;;
  port=*)
    z.arg.named.literal port "$@" && local port=$REPLY
    if ! z.int.is.lteq ${#port} 5 || [[ $port != <1-65535> ]]; then
      z.io.error "Invalid TCP port: $port"
      return 1
    fi

    # localの終了コードで上書きされる前に、コマンド置換の成否を保存する。
    local pids=(${(f)"$(lsof -nP -t -iTCP:$port -sTCP:LISTEN)"}) lookup_status=$?
    if z.int.is.not.zero "$lookup_status"; then
      z.io.error "Unable to resolve TCP listeners for port: $port"
      return 1
    fi
    ;;
  name=*)
    z.arg.named.literal name "$@" && local name=$REPLY
    if z.is.null "$name"; then
      z.io.error "Process name is required"
      return 1
    fi

    local listing="$(ps -A -o pid= -o comm=)" lookup_status=$?
    if z.int.is.not.zero "$lookup_status"; then
      z.io.error "Unable to list processes"
      return 1
    fi

    local pids=()
    local process_pid process_name
    while IFS=$' \t' read -r process_pid process_name; do
      z.is.eq "$process_name" "$name" && pids+=("$process_pid")
    done <<< "$listing"
    ;;
  *)
    z.io.error "Specify exactly one of pid=, port=, or name="
    return 1
    ;;
  esac

  if z.int.is.zero ${#pids}; then
    z.io.error "No matching process: $1"
    return 1
  fi

  local target_pid
  for target_pid in "${pids[@]}"; do
    if ! z.int.is.lteq ${#target_pid} 10 || [[ $target_pid != <1-2147483647> ]]; then
      z.io.error "Invalid process ID: $target_pid"
      return 1
    fi
  done

  z.return "${(@u)pids}"
}
