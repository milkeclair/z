# get the z.job queue root
#
# REPLY: queue root path
# return: null
#
# example:
#  z.job.file._root
z.job.file._root() {
  z.return "/tmp/z/job/$$"
}

# get the z.job jobs directory
#
# REPLY: jobs directory path
# return: null
#
# example:
#  z.job.file._jobs
z.job.file._jobs() {
  z.job.file._root
  z.return "$REPLY/jobs"
}

# get a z.job directory path
#
# $id: job id
# REPLY: job directory path
# return: 0|1
#
# example:
#  z.job.file._dir id=20260623T121530000000000.100.1
z.job.file._dir() {
  z.arg.named id "$@" && local id=$REPLY
  z.is.null "$id" && return 1

  z.job.file._jobs
  z.return "$REPLY/$id"
}

# get a z.job file path
#
# $id: job id
# $name: file name
# REPLY: job file path
# return: 0|1
#
# example:
#  z.job.file._path id=20260623T121530000000000.100.1 name=status
z.job.file._path() {
  z.arg.named id "$@" && local id=$REPLY
  z.arg.named name "$@" && local name=$REPLY

  z.is.null "$id" && return 1
  z.is.null "$name" && return 1

  z.job.file._dir id=$id || return 1
  z.return "$REPLY/$name"
}
