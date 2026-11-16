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

# print process IDs, names and visible TCP listening ports
# accepts at most one selector; with none, lists all processes
#
# $pid?: positive process ID
# $port?: TCP listening port used to select processes
# $name?: exact process name from ps comm
# stdout: tab-separated PID, NAME and PORTS header and rows
# REPLY: tab-separated rows without the header
# return: 0 on success, otherwise 1
#
# example:
#  z.process.list
#  z.process.list port=3000
z.process.list() {
  local -A selected=()
  local pid name
  if z.arg.is.present "$@"; then
    if ! z.process._pids "$@"; then
      z.return
      return 1
    fi
    for pid in "${REPLY[@]}"; do
      selected[$pid]=true
    done
  fi

  local listing="$(ps -A -o pid= -o comm=)" lookup_status=$?
  if z.int.is.not.zero "$lookup_status"; then
    z.io.error "Unable to list processes"
    z.return
    return 1
  fi
  if ! z.process.list._ports; then
    return 1
  fi
  local -A ports=($REPLY)

  local rows=()
  while IFS=$' \t' read -r pid name; do
    z.is.null "$pid" && continue
    if z.arg.is.present "$@" && z.is.not.eq "${selected[$pid]:-}" true; then
      continue
    fi
    rows+=("$pid"$'\t'"$name"$'\t'"${ports[$pid]:--}")
  done <<< "$listing"

  if z.arg.is.present "$@" && z.int.is.zero ${#rows}; then
    z.io.error "No matching process: $1"
    z.return
    return 1
  fi

  z.arr.join.line "${rows[@]}"
  local result=$REPLY
  z.io.literal $'PID\tNAME\tPORTS'
  z.is.not.null "$result" && z.io.literal "$result"
  z.return "$result"
}
