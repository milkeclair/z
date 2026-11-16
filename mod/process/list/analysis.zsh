# collect visible TCP listening ports, grouped by PID
#
# REPLY: PID/port-list key-value pairs; empty when no listeners are reported
# return: 0 on success, otherwise 1
#
# example:
#  z.process.list._ports
z.process.list._ports() {
  local listing="$(lsof -nP -w -iTCP -sTCP:LISTEN -Fpn 2>&1)" lookup_status=$?
  REPLY=()
  if z.int.is.eq "$lookup_status" 1 && z.is.null "$listing"; then
    return 0
  fi
  if z.int.is.not.zero "$lookup_status"; then
    z.io.error "Unable to list TCP listeners: $listing"
    REPLY=()
    return 1
  fi

  local -A ports=()
  local pid=0
  local invalid=false
  local line
  for line in "${(@f)listing}"; do
    case $line in
    p*)
      pid=${line#p}
      if ! z.int.is.lteq ${#pid} 10 || [[ $pid != <1-2147483647> ]]; then
        invalid=true
        break
      fi
      ;;
    n*)
      local port=${line##*:}
      if z.int.is.zero "$pid" || ! z.int.is.lteq ${#port} 5 || [[ $port != <1-65535> ]]; then
        invalid=true
        break
      fi
      ports[$pid]="${ports[$pid]:-} $port"
      ;;
    "")
      ;;
    *)
      invalid=true
      break
      ;;
    esac
  done

  if z.is.true "$invalid"; then
    z.io.error "Invalid TCP listener record: $line"
    REPLY=()
    return 1
  fi

  for pid in "${(@k)ports}"; do
    local values=(${=ports[$pid]})
    z.arr.unique "${values[@]}"
    local sorted=(${(on)REPLY})
    z.arr.join delimiter=, "${sorted[@]}"
    ports[$pid]=$REPLY
  done

  z.hash.entries ports literal=true
}
