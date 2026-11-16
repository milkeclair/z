# z.jobのキュールートを取得する
#
# REPLY: キュールートのパス
# return: null
#
# example:
#  z.job.file._root
z.job.file._root() {
  REPLY="/tmp/z/job/$$"
}

# z.jobのジョブ保存ディレクトリを取得する
#
# REPLY: ジョブ保存ディレクトリのパス
# return: null
#
# example:
#  z.job.file._jobs
z.job.file._jobs() {
  z.job.file._root
  REPLY="$REPLY/jobs"
}

# z.jobのディレクトリパスを取得する
#
# $id: ジョブID
# REPLY: ジョブディレクトリのパス
# return: 0|1
#
# example:
#  z.job.file._dir id=20260623T121530000000000.100.1
z.job.file._dir() {
  z.arg.named id "$@" && local id=$REPLY
  z.is.null "$id" && return 1

  z.job.file._jobs
  REPLY="$REPLY/$id"
}

# z.jobのファイルパスを取得する
#
# $id: ジョブID
# $name: ファイル名
# REPLY: ジョブファイルのパス
# return: 0|1
#
# example:
#  z.job.file._path id=20260623T121530000000000.100.1 name=status
z.job.file._path() {
  z.arg.named id "$@" && local id=$REPLY
  z.arg.named name "$@" && local name=$REPLY

  z.is.null "$id" && return 1
  z.is.null "$name" && return 1

  z.job.file._dir id=$id
  REPLY="$REPLY/$name"
}
