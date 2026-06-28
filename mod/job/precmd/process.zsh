# register z.job collection in precmd
#
# REPLY: null
# return: 0|1
#
# example:
#  z.job.precmd._register
z.job.precmd._register() {
  local -a registered_functions=("${precmd_functions[@]}")
  if z.arr.includes target=z.job.collect "${registered_functions[@]}"; then
    return 0
  fi

  autoload -Uz add-zsh-hook
  add-zsh-hook precmd z.job.collect
}
