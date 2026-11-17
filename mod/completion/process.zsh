typeset -gA z_completion_docs=()
typeset -gA z_completion_argument_specs=()
typeset -ga z_completion_function_names=()
typeset -g z_completion_cache_ready=false
typeset -g z_completion_cache_job_id=""
typeset -g z_completion_command_function

# -cを指定しない対話シェルでzの関数補完を有効にする
#
# REPLY: null
# return: 0|1
#
# example:
#  # -cなしの対話シェルで、compinit済みの場合
#  z.completion.enable
#  # return: 0
#  # z_completion_cache_job_idの例: "20260623T121530000000000.100.1"
z.completion.enable() {
  z.completion.is._interactive || return 0

  z.completion.cache.build._names
  z.completion.compdef._ignore_private
  z.completion.compdef._register || return 1
  autoload -Uz add-zsh-hook
  add-zsh-hook zshexit z.completion.cache._cancel
  z.completion.cache._cancel

  z.job.run \
    name=completion-cache command=z.completion.cache.build._result on_success=z.completion.cache.load._result || return 1 # zls: ignore
  z_completion_cache_job_id=$REPLY
}
