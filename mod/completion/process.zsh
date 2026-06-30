typeset -gA z_completion_docs=()
typeset -ga z_completion_function_names=()
typeset -g z_completion_cache_ready=false

# enable z function completion
#
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.enable
z.completion.enable() {
  z.completion.cache.build._names
  z.completion.compdef._ignore_private || return 1
  z.completion.compdef._register || return 1
  z.job.run \
    name=completion-cache command=z.completion.cache.build._result on_success=z.completion.cache.load._result # zls: ignore
}
