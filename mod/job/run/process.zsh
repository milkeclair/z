# prepare a job directory
#
# $name: job name
# $command: child function name
# $on_success?: parent success callback function name
# $on_failure?: parent failure callback function name
# REPLY: job id and job directory
# return: 0|1
#
# example:
#  z.job.run._prepare name=example command=z.example.build
z.job.run._prepare() {
  z.arg.named name "$@" && local name=$REPLY
  z.arg.named command "$@" && local command=$REPLY
  z.arg.named on_success "$@" && local on_success=$REPLY
  z.arg.named on_failure "$@" && local on_failure=$REPLY

  z.is.null "$name" && return 1
  z.is.null "$command" && return 1

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

  z.return "$id" "$dir"
}

# spawn a job child process
#
# $id: job id
# $dir: job directory
# REPLY: child process id
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
  z.return "$!"
}

# execute a job command in the child process
#
# $id: job id
# $dir: job directory
# REPLY: null
# return: command status
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
