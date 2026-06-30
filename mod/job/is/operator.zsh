# check whether a job is running
#
# $id: job id
# REPLY: null
# return: 0|1
#
# example:
#  z.job.is.running id=20260623T121530000000000.100.1
z.job.is.running() {
  z.arg.named id "$@" && local id=$REPLY
  z.is.null "$id" && return 1

  z.job.status id="$id" || return 1
  z.is.eq "$REPLY" "running" || return 1

  z.job.file._path id=$id name=pid
  z.file.read path="$REPLY" && local pid=$REPLY
  z.is.null "$pid" && return 1

  kill -0 "$pid" >/dev/null 2>&1
}
