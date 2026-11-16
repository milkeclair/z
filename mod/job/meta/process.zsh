# ジョブのメタデータを書き込む
#
# $id: ジョブID
# $name: ジョブ名
# $command: コマンド関数名
# $dir: ジョブのディレクトリ
# $on_success?: 成功時のコールバック関数名
# $on_failure?: 失敗時のコールバック関数名
# REPLY: null
# return: null
#
# example:
#  # /tmp/jobが存在する場合
#  z.job.meta._write id=job name=example command=z.version dir=/tmp/job
#  # /tmp/job/metaの一部: z_job_name="example"、z_job_command="z.version"
z.job.meta._write() {
  z.arg.named id "$@" && local id=$REPLY
  z.arg.named name "$@" && local name=$REPLY
  z.arg.named command "$@" && local command=$REPLY
  z.arg.named on_success "$@" && local on_success=$REPLY
  z.arg.named on_failure "$@" && local on_failure=$REPLY
  z.arg.named dir "$@" && local dir=$REPLY

  local lines=()
  lines+=("z_job_id=${(qqq)id}")
  lines+=("z_job_name=${(qqq)name}")
  lines+=("z_job_command=${(qqq)command}")
  lines+=("z_job_on_success=${(qqq)on_success}")
  lines+=("z_job_on_failure=${(qqq)on_failure}")
  lines+=("z_job_dir=${(qqq)dir}")

  z.file.write path="$dir/meta" content=""
  for line in "${lines[@]}"; do
    z.file.write.last path="$dir/meta" content="$line"
  done
}

# ジョブのメタデータを読む
#
# $dir: ジョブのディレクトリ
# REPLY: null
# return: 0|1
#
# example:
#  # metaにz_job_name="example"とz_job_command="z.version"が保存されている場合
#  z.job.meta._read dir=/tmp/job
#  # return: 0
#  # 読み込み後: z_job_name="example"、z_job_command="z.version"
z.job.meta._read() {
  z.arg.named dir "$@" && local dir=$REPLY
  z.is.null "$dir" && return 1

  local meta_file="$dir/meta"
  z.file.exists "$meta_file" || return 1
  source "$meta_file"
}
