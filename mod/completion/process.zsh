typeset -gA z_completion_docs=()
typeset -ga z_completion_function_names=()
typeset -g z_completion_cache_ready=false
typeset -g z_completion_cache_job_id=""

# enable z function completion in interactive shells without -c
#
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.enable
z.completion.enable() {
  z.completion.is._interactive || return 0

  z.completion.cache.build._names
  z.completion.compdef._ignore_private || return 1
  z.completion.compdef._register || return 1
  autoload -Uz add-zsh-hook
  add-zsh-hook zshexit z.completion.cache._cancel || return 1
  z.completion.cache._cancel

  z.job.run \
    name=completion-cache command=z.completion.cache.build._result on_success=z.completion.cache.load._result || return 1 # zls: ignore
  z_completion_cache_job_id=$REPLY
}
