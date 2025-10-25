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
  z.arr.count $z_t_logs
  local idx=$REPLY

  case $context in
  "describe")
    z.t._state.current_idx.set "describe" value=$idx
    z.t._state.current_idx.set "context" value=0
    z.t._state.current_idx.set "it" value=0
    ;;
  "context")
    z.t._state.current_idx.set "context" value=$idx
    z.t._state.current_idx.set "it" value=0
    ;;
  "it")
    z.t._state.current_idx.set "it" value=$idx
    ;;
  esac

  z.return $idx
}
