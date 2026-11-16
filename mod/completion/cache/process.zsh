# 関数名とドキュメントの補完キャッシュを作成する
#
# REPLY: null
# return: null
#
# example:
#  z.completion.cache._build
#  # 変更後: z_completion_cache_ready=true
#  # 結果: 現在の関数名と説明で補完キャッシュが作り直される
z.completion.cache._build() {
  z_completion_cache_ready=false
  z_completion_docs=()
  z.completion.cache.build._names
  z.completion.cache.build._docs
  z_completion_cache_ready=true
}

# 現在のシェルが所有する未完了の補完処理をキャンセルする
#
# REPLY: null
# return: 0
#
# example:
#  local z_completion_cache_job_id=""
#  z.completion.cache._cancel
#  # return: 0
#  # REPLY: ""
#  # 変更後: z_completion_cache_job_id=""
z.completion.cache._cancel() {
  local id=$z_completion_cache_job_id
  z_completion_cache_job_id=""
  z.is.null "$id" && REPLY="" && return 0

  if z.job.status id="$id" >/dev/null; then
    local job_state=$REPLY
    if z.is.eq "$job_state" queued || z.is.eq "$job_state" running; then
      z.job.cancel id="$id"
    fi
  fi

  REPLY=""
}
