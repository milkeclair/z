# collect one job directory
#
# $dir: job directory
# REPLY: collected job id|null
# return: 0|1
#
# example:
#  z.job.collect._one dir=/tmp/z/job/123/jobs/job
z.job.collect._one() {
  z.arg.named dir "$@" && local dir=$REPLY
  z.is.null "$dir" && return 1

  z.job.meta._read dir="$dir" || {
    z.return
    return 0
  }
  local id=$z_job_id

  z.file.read path="$dir/status"
  local job_status=$REPLY

  if z.is.eq "$job_status" "running"; then
    z.job.is.running id="$id" && {
      z.return
      return 0
    }
    z.file.write path="$dir/exit" content=1
    z.file.write path="$dir/status" content=failure
    job_status=failure
  fi

  z.is.eq "$job_status" "queued" && {
    z.return
    return 0
  }
  if z.is.not.eq "$job_status" "success" && z.is.not.eq "$job_status" "failure"; then
    z.return
    return 0
  fi

  local failed=false
  z.job.collect._callback dir="$dir" status="$job_status" || failed=true
  z.dir.remove path="$dir"
  z.return "$id"
  z.is.true "$failed" && return 1
  return 0
}

# run a callback for a collected job
#
# $dir: job directory
# $status: collected status
# REPLY: null
# return: 0|1
#
# example:
#  z.job.collect._callback dir=/tmp/z/job/123/jobs/job status=success
z.job.collect._callback() {
  z.arg.named dir "$@" && local dir=$REPLY
  z.arg.named status "$@" && local job_status=$REPLY

  z.job.meta._read dir="$dir" || return 1
  z.file.read path="$dir/exit"
  local exit_status=${REPLY:-1}

  local callback=""
  if z.is.eq "$job_status" "success"; then
    callback=$z_job_on_success
  elif z.is.eq "$job_status" "failure"; then
    callback=$z_job_on_failure
  fi

  z.is.null "$callback" && return
  "$callback" \
    id="$z_job_id" \
    name="$z_job_name" \
    dir="$dir" \
    result="$dir/result" \
    exit_status="$exit_status"
}
