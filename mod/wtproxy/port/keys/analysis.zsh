# 設定の連想配列からworktreeポートキーを取り出す
#
# $1: 設定の連想配列名
# REPLY: 連番のポートキー
# return: null
#
# example:
#  local -A config=(proxy_port_1 3000 proxy_port_3 5173)
#  z.wtproxy._port.keys.from_config config
#  # REPLY: ("worktree_port_1" "worktree_port_3")
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

  REPLY=("${keys[@]}")
}
