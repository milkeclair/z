# 1つのプロセス指定から、重複のない正のPIDを解決する
#
# $pid?: プロセスID（1..2147483647）
# $port?: TCP待受ポート（1..65535、lsofが必要）
# $name?: ps commと完全一致で照合するプロセス名（psが必要）
# REPLY: 成功時に一致したPID
# return: 解決できた場合は0、それ以外は1
#
# example:
#  z.process._pids pid=12345
#  # REPLY: ("12345")
#  # return: 0
z.process._pids() {
  if ! z.int.is.eq $# 1; then
    z.io.error "Specify exactly one of pid=, port=, or name="
    return 1
  fi

  case $1 in
  pid=*)
    z.arg.named pid "$@" && local pid=$REPLY
    local pids=("$pid")
    ;;
  port=*)
    z.arg.named port "$@" && local port=$REPLY
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
    z.arg.named name "$@" && local name=$REPLY
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

  REPLY=("${(@u)pids}")
}

# プロセスID・名前・取得可能なTCP待受ポートを表示する
# 絞り込みの指定は最大1つ。指定がなければ全プロセスを一覧する
#
# $pid?: 正のプロセスID
# $port?: プロセスの選択に使うTCP待受ポート
# $name?: ps commと完全一致で照合するプロセス名
# REPLY: ヘッダーを除いたタブ区切りの行
# return: 成功時は0、それ以外は1
#
# example:
#  # PID12345のnodeがTCP3000を待ち受けている場合
#  z.process.list pid=12345
#  # 出力:
#  # PID<TAB>NAME<TAB>PORTS
#  # 12345<TAB>node<TAB>3000
#  # REPLY: $'12345\tnode\t3000'
#  # return: 0
z.process.list() {
  local -A selected=()
  local pid name
  if z.arg.is.present "$@"; then
    if ! z.process._pids "$@"; then
      REPLY=""
      return 1
    fi
    for pid in "${REPLY[@]}"; do
      selected[$pid]=true
    done
  fi

  local listing="$(ps -A -o pid= -o comm=)" lookup_status=$?
  if z.int.is.not.zero "$lookup_status"; then
    z.io.error "Unable to list processes"
    REPLY=""
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
    REPLY=""
    return 1
  fi

  z.arr.join.line "${rows[@]}"
  local result=$REPLY
  z.io message=$'PID\tNAME\tPORTS'
  z.is.not.null "$result" && z.io message="$result"
  REPLY="$result"
}
