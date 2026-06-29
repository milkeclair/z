# get a job status
#
# $id: job id
# REPLY: job status|null
# return: 0|1
#
# example:
#  z.job.status id=20260623T121530000000000.100.1
z.job.status() {
  z.arg.named id "$@" && local id=$REPLY
  z.is.null "$id" && return 1

  z.job.file._path id=$id name=status || return 1
  local status_file=$REPLY
  z.file.exists "$status_file" || return 1

  z.file.read path="$status_file"
}

# list queued jobs
#
# REPLY: tab-separated job lines
# return: null
#
# example:
#  z.job.list
z.job.list() {
  z.job.file._jobs
  local jobs_dir=$REPLY

  if z.dir.not.exists "$jobs_dir"; then
    z.return && return
  fi

  local lines=()
  for job_dir in "$jobs_dir"/*(N/); do
    z.job.meta._read dir="$job_dir" || continue
    local job_status=""
    local status_file="$job_dir/status"
    if z.file.exists "$status_file" && z.file.read path="$status_file"; then
      job_status=$REPLY
    fi
    lines+=("$z_job_id	$z_job_name	$job_status")
  done

  z.arr.join.line "${lines[@]}"
}
