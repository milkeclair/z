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
