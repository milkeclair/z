# extract worktree port keys from a configuration hash
#
# $1: configuration hash name
# REPLY: numbered port keys
# return: null
#
# example:
#  z.wtproxy._port.keys.from_config config
z.wtproxy._port.keys.from_config() {
  local config_name=$1
  local -A seen=()
  local max_index=0

  z.hash.keys $config_name
  for config_key in ${(@)REPLY}; do
    z.wtproxy._port.proxy.index $config_key || continue
    local port_index=$REPLY

    local value_ref="${config_name}[$config_key]"
    z.var.get $value_ref
    z.is.null $REPLY && continue

    seen[$port_index]=true
    z.int.is.gt $port_index $max_index && max_index=$port_index
  done

  local keys=()
  for ((port_index=1; port_index<=max_index; port_index++)); do
    z.is.true $seen[$port_index] || continue
    z.wtproxy._port.worktree.key $port_index
    keys+=($REPLY)
  done

  z.return ${keys[@]}
}
