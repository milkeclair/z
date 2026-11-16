# 引数を検証してからジョブディレクトリを用意する
#
# $name: ジョブ名
# $command: 子で実行する関数名
# $on_success?: 親プロセスの成功時コールバック関数名
# $on_failure?: 親プロセスの失敗時コールバック関数名
# REPLY: ジョブIDとジョブディレクトリ
# return: null
#
# example:
#  z.job.run._prepare name=example command=z.example.build
z.job.run._prepare() {
  z.arg.named name "$@" && local name=$REPLY
  z.arg.named command "$@" && local command=$REPLY
  z.arg.named on_success "$@" && local on_success=$REPLY
  z.arg.named on_failure "$@" && local on_failure=$REPLY

  z.job.file._jobs && local jobs_dir=$REPLY
  z.dir.exists "$jobs_dir" || z.dir.make path="$jobs_dir"

  z.job.id._generate && local id=$REPLY
  z.job.file._dir id="$id" && local dir=$REPLY
  z.dir.exists "$dir" || z.dir.make path="$dir"

  z.job.meta._write \
    id="$id" \
    name="$name" \
    command="$command" \
    on_success="$on_success" \
    on_failure="$on_failure" \
    dir="$dir"
  z.file.write path="$dir/status" content=queued
  z.file.write path="$dir/exit" content=""
  z.file.make path="$dir/result"
  z.file.make path="$dir/stdout"
  z.file.make path="$dir/stderr"

  REPLY=("$id" "$dir")
}

# ジョブの子プロセスを起動する
#
# $id: ジョブID
# $dir: ジョブのディレクトリ
# REPLY: 子プロセスのID
# return: 0|1
#
# example:
#  z.job.run._spawn id=job dir=/tmp/z/job/123/jobs/job
z.job.run._spawn() {
  z.arg.named id "$@" && local id=$REPLY
  z.arg.named dir "$@" && local dir=$REPLY

  z.is.null "$id" && return 1
  z.is.null "$dir" && return 1

  zsh -f -c 'source "$1"; z.job.run._child id="$2" dir="$3"' \
    z_job_child "$z_root/main.zsh" "$id" "$dir" \
    > "$dir/stdout" 2> "$dir/stderr" &!
  REPLY="$!"
}

# 子プロセスでジョブのコマンドを実行する
#
# $id: ジョブID
# $dir: ジョブのディレクトリ
# REPLY: null
# return: コマンドの終了コード
#
# example:
#  z.job.run._child id=job dir=/tmp/z/job/123/jobs/job
z.job.run._child() {
  z.arg.named id "$@" && local id=$REPLY
  z.arg.named dir "$@" && local dir=$REPLY

  z.job.meta._read dir="$dir" || return 1
  z.file.write path="$dir/status" content=running

  "$z_job_command" id="$id" name="$z_job_name" dir="$dir" result="$dir/result"
  local exit_status=$?

  z.file.write path="$dir/exit" content="$exit_status"
  if z.int.is.zero $exit_status; then
    z.file.write path="$dir/status" content=success
  else
    z.file.write path="$dir/status" content=failure
  fi

  return $exit_status
}
