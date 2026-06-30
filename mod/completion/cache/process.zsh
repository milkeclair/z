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
