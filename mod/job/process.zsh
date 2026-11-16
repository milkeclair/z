# バックグラウンドでジョブを実行する
#
# $name: ジョブ名
# $command: 子で実行する関数名
# $on_success?: 親プロセスの成功時コールバック関数名
# $on_failure?: 親プロセスの失敗時コールバック関数名
# REPLY: ジョブID
# return: 0|1
#
# example:
#  z.job.run name=example command=z.example.build on_success=z.example.load
z.job.run() {
  z.arg.named name "$@" && local name=$REPLY
  z.arg.named command "$@" && local command=$REPLY
  z.arg.named on_success "$@" && local on_success=$REPLY
  z.arg.named on_failure "$@" && local on_failure=$REPLY

  z.job.run._validate \
    name="$name" \
    command="$command" \
    on_success="$on_success" \
    on_failure="$on_failure" || return 1

  z.job.run._prepare \
    name="$name" \
    command="$command" \
    on_success="$on_success" \
    on_failure="$on_failure"
  local -a prepared=("${REPLY[@]}")
  local id=$prepared[1]
  local dir=$prepared[2]

  if ! z.job.precmd._register; then
    z.dir.remove path="$dir"
    return 1
  fi

  if ! z.job.run._spawn id="$id" dir="$dir"; then
    z.dir.remove path="$dir"
    return 1
  fi
  local pid=$REPLY
  z.file.write path="$dir/pid" content="$pid"

  REPLY="$id"
  return 0
}

# 終了済みのジョブを回収する
#
# REPLY: 回収したジョブID
# return: 0|1
#
# example:
#  z.job.collect
z.job.collect() {
  z.job.file._jobs && local jobs_dir=$REPLY
  if z.dir.not.exists "$jobs_dir"; then
    REPLY="" && return
  fi

  local collected=()
  local failed=false
  for job_dir in "$jobs_dir"/*(N/); do
    z.job.collect._one dir="$job_dir" || failed=true
    local collected_id=$REPLY
    z.is.not.null "$collected_id" && collected+=("$collected_id")
  done

  z.arr.join.line "${collected[@]}"
  z.is.true "$failed" && return 1
  return 0
}

# ジョブをキャンセルする
#
# $id: ジョブID
# REPLY: null
# return: 0|1
#
# example:
#  z.job.cancel id=20260623T121530000000000.100.1
z.job.cancel() {
  z.arg.named id "$@" && local id=$REPLY
  z.is.null "$id" && return 1

  z.job.file._dir id="$id" && local dir=$REPLY
  z.dir.exists "$dir" || return 1
  z.job.meta._read dir="$dir" || return 1

  z.file.read path="$dir/pid" && local pid=$REPLY
  z.is.not.null "$pid" && kill "$pid" >/dev/null 2>&1
  z.dir.remove path="$dir"
}
