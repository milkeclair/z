# Install temporary DEBUG interception for one method block.
#
# $1: method name
# $2: defining caller stack
# $3: defining source file
# $4: discard the invalid definition when 1
# REPLY: unchanged
# return: 0
z.cls.capture.start() {
  typeset -g z_cls_capture_discard=${4:-0} z_cls_capture_done_result=0
  typeset -g z_cls_capture_stack=$2 z_cls_capture_file=$3 z_cls_capture_body=''
  typeset -g z_cls_debug_function="${functions[TRAPDEBUG]-}"
  typeset -g z_cls_debug_has_function=${+functions[TRAPDEBUG]} z_cls_debug_trap=''
  typeset -g z_cls_debug_before=$options[debugbeforecmd] z_cls_debug_localtraps=$options[localtraps]
  local trap_line
  local -a trap_words
  for trap_line in "${(@f)$(trap)}"; do
    [[ $trap_line == 'trap -- '* ]] || continue
    trap_words=(${(z)trap_line})
    [[ $trap_words[4] == DEBUG ]] && z_cls_debug_trap=$trap_line
  done
  unsetopt localtraps
  setopt debugbeforecmd
  functions[TRAPDEBUG]='unsetopt localoptions; z.cls.capture.debug "$ZSH_DEBUG_CMD"'
  z_cls_capture_method=$1
}

# Restore the previous DEBUG handler and its timing option.
#
# REPLY: unchanged
# return: 0
z.cls.capture.stop() {
  [[ -n ${z_cls_capture_method:-} ]] || return 0
  z_cls_capture_method=''
  trap - DEBUG
  if [[ $z_cls_debug_has_function == 1 ]]; then
    functions[TRAPDEBUG]=$z_cls_debug_function
  elif [[ -n $z_cls_debug_trap ]]; then
    eval "$z_cls_debug_trap"
  fi
  [[ $z_cls_debug_before == on ]] || unsetopt debugbeforecmd
  [[ $z_cls_debug_localtraps == off ]] || setopt localtraps
  return 0
}

# Collect a pending command and skip its execution, or finish at the marker.
# A changed caller stack aborts a definition that left its source unexpectedly.
#
# $1: Zsh's reconstructed command text
# REPLY: unchanged
# return: 0
z.cls.capture.debug() {
  [[ -n ${z_cls_capture_method:-} ]] || return 0
  if [[ ${(j:|:)funcstack[3,-1]} != "$z_cls_capture_stack" ||
        $1 == z.cls.drew || $1 == z.cls.abort ]]; then
    z.cls.abort
    z.io.error "Unfinished class method in $z_cls_capture_file; definition discarded."
    return 0
  fi
  if [[ $1 == z.cls.fn.done ]]; then
    if [[ $z_cls_capture_discard == 1 ]]; then
      z.cls.abort
      z_cls_capture_done_result=1
    else
      z_cls_bodies[$z_cls_drawing:$z_cls_capture_method]=$z_cls_capture_body
      z_cls_class_methods[$z_cls_drawing]+="$z_cls_capture_method "
      z.cls.capture.stop
    fi
  else
    z_cls_capture_body+="$1"$'\n'
    setopt errexit
  fi
}
