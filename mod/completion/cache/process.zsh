# build completion caches for function names and docs
#
# REPLY: null
# return: null
#
# example:
#  z.completion.cache._build
z.completion.cache._build() {
  z_completion_cache_ready=false
  z_completion_docs=()
  z.completion.cache.build._names
  z.completion.cache.build._docs
  z_completion_cache_ready=true
}

# cancel unfinished completion work owned by the current shell
#
# REPLY: null
# return: 0
#
# example:
#  z.completion.cache._cancel
z.completion.cache._cancel() {
  local id=$z_completion_cache_job_id
  z_completion_cache_job_id=""
  z.is.null "$id" && z.return && return 0

  if z.job.status id="$id" >/dev/null; then
    local job_state=$REPLY
    if z.is.eq "$job_state" queued || z.is.eq "$job_state" running; then
      z.job.cancel id="$id"
    fi
  fi

  z.return
}
