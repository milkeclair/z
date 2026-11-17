# ジョブ実行の引数を検証する
#
# $name: ジョブ名
# $command: 子で実行する関数名
# $on_success?: 親プロセスの成功時コールバック関数名
# $on_failure?: 親プロセスの失敗時コールバック関数名
# REPLY: null
# return: 0|1
#
# example:
#  z.job.run._validate name=version command=z.version
#  # return: 0
z.job.run._validate() {
  z.arg.named name "$@" && local name=$REPLY
  z.arg.named command "$@" && local command=$REPLY
  z.arg.named on_success "$@" && local on_success=$REPLY
  z.arg.named on_failure "$@" && local on_failure=$REPLY

  z.is.null "$name" && return 1
  z.is.null "$command" && return 1
  ! z.hash.has.key functions "key=$command" && return 1
  z.is.not.null "$on_success" && ! z.hash.has.key functions "key=$on_success" && return 1
  z.is.not.null "$on_failure" && ! z.hash.has.key functions "key=$on_failure" && return 1

  return 0
}
