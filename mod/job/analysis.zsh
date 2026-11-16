# ジョブの状態を表示して返す
#
# $id: ジョブID
# stdout: ジョブの状態
# REPLY: ジョブの状態|null
# return: 0|1
#
# example:
#  # 指定したジョブがsuccess状態で残っている場合
#  z.job.status id=20260623T121530000000000.100.1
#  # 出力: success
#  # REPLY: "success"
#  # return: 0
z.job.status() {
  z.arg.named id "$@" && local id=$REPLY
  z.is.null "$id" && return 1

  z.job.file._path id=$id name=status
  local status_file=$REPLY
  z.file.exists "$status_file" || return 1

  z.file.read path="$status_file" || return 1
  local result=$REPLY
  z.io "$result"
  REPLY="$result"
}

# 待機中のジョブを表示して返す
#
# stdout: タブ区切りのジョブの行（ジョブがなければ空）
# REPLY: タブ区切りのジョブの行
# return: null
#
# example:
#  # 指定のID・名前example・状態queuedのジョブが1件ある場合
#  z.job.list
#  # 表示例: 20260623T121530000000000.100.1<TAB>example<TAB>queued
#  # REPLY: $'20260623T121530000000000.100.1\texample\tqueued'
z.job.list() {
  z.job.file._jobs
  local jobs_dir=$REPLY

  if z.dir.not.exists "$jobs_dir"; then
    REPLY="" && return
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
  z.is.null "$REPLY" && return 0
  local result=$REPLY
  z.io "$result"
  REPLY="$result"
}
