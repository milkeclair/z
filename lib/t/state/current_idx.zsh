typeset -A z_t_current_idx=([describe]=0 [context]=0 [it]=0)

# get the current index for a context
#
# $1: context ("describe"|"context"|"it")
# REPLY: null
# return: current index
#
# example:
#  z.t._state.current_idx "describe"  #=> 0
z.t._state.current_idx() {
  local context=$1
  z.return ${z_t_current_idx[$context]}
}

# set the current index for a context
#
# $value: index value
# $@: context ("describe"|"context"|"it")
# REPLY: null
# return: null
#
# example:
#  z.t._state.current_idx.set "describe" value=1
z.t._state.current_idx.set() {
  local REPLY
  z.arg.named value $@ && local value=$REPLY
  z.arg.named.shift value $@ && local context=$REPLY

  z_t_current_idx[$context]=$value
}

# add to the current index for a context
#
# $1: context ("describe"|"context"|"it")
# REPLY: null
# return: new index value
#
# example:
#  z.t._state.current_idx.add "describe"
z.t._state.current_idx.add() {
  local context=$1
  local logs=($z_t_logs)
  local idx=${#logs}

  case $context in
  "describe")
    z_t_current_idx[describe]=$idx
    z_t_current_idx[context]=0
    z_t_current_idx[it]=0
    ;;
  "context")
    z_t_current_idx[context]=$idx
    z_t_current_idx[it]=0
    ;;
  "it")
    z_t_current_idx[it]=$idx
    ;;
  esac

  z.return $idx
}
