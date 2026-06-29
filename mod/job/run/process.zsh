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
