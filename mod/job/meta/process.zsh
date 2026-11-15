# write job metadata
#
# $id: job id
# $name: job name
# $command: command function name
# $dir: job directory
# $on_success?: success callback function name
# $on_failure?: failure callback function name
# REPLY: null
# return: null
#
# example:
#  z.job.meta._write id=job name=example command=z.example.run dir=/tmp/job
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

# read job metadata
#
# $dir: job directory
# REPLY: null
# return: 0|1
#
# example:
#  z.job.meta._read dir=/tmp/z/job/123/jobs/id
z.job.meta._read() {
  z.arg.named dir "$@" && local dir=$REPLY
  z.is.null "$dir" && return 1

  local meta_file="$dir/meta"
  z.file.exists "$meta_file" || return 1
  source "$meta_file"
}
