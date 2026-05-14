# get port keys from a configuration hash
#
# $1: configuration hash name
# REPLY: numbered port keys
# return: null
#
# example:
#  z.wt_proxy._port.keys.from_config config
z.wt_proxy._port.keys.from_config() {
  local config_name=$1
  local -A seen=()
  local max_index=0

  for config_key in ${(Pk)config_name}; do
    z.wt_proxy._port.public.config.index $config_key || continue
    local port_index=$REPLY

    local value_ref="${config_name}[$config_key]"
    z.var.get $value_ref
    z.is.null $REPLY && continue

    seen[$port_index]=true
    if (( port_index > max_index )); then
      max_index=$port_index
    fi
  done

  local keys=()
  for ((port_index=1; port_index<=max_index; port_index++)); do
    z.is.true $seen[$port_index] || continue
    z.wt_proxy._port.key $port_index
    keys+=($REPLY)
  done

  z.return ${keys[@]}
}
