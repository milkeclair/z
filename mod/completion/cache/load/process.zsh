# ジョブの結果ファイルから補完キャッシュを読み込む
#
# $result: 結果ファイルのパス
# REPLY: null
# return: 0|1
#
# example:
#  # compinit済みで、resultに有効なキャッシュがある場合
#  z.completion.cache.load._result result=/tmp/z/job/result
#  # return: 0
#  # 変更後: z_completion_cache_ready=true
z.completion.cache.load._result() {
  z.arg.named result "$@" && local result=$REPLY
  z.is.null "$result" && return 1

  source "$result"
  z.completion.compdef._register
}
