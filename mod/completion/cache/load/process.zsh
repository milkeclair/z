# ジョブの結果ファイルから補完キャッシュを読み込む
#
# $result: 結果ファイルのパス
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.cache.load._result result=/tmp/z/job/result
z.completion.cache.load._result() {
  z.arg.named result "$@" && local result=$REPLY
  z.is.null "$result" && return 1

  source "$result"
  z.completion.compdef._register
}
