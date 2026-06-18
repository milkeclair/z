# print a proxy entry
#
# $@: entry hash as key-value pairs
# REPLY: null
# return: 0 if configuration is available, otherwise 1
#
# example:
#  z.wtproxy._print.entry "${(@kv)entry}"
z.wtproxy._print.entry() {
  local -A entry=("$@")

  z.wtproxy._config || return 1
  local -A config=("${(@)REPLY}")

  z.io "path: $entry[path]"
  z.io "branch: $entry[branch]"
  z.io "compose_project_name: $entry[compose_project_name]"

  z.wtproxy._port.keys.from_config config

  for port_key in ${(@)REPLY}; do
    z.wtproxy._port.worktree.index $port_key
    local port_index=$REPLY
    z.wtproxy._port.proxy.key $port_index
    local proxy_key=$REPLY

    z.io "$port_key: $config[host]:$config[$proxy_key] -> $config[host]:$entry[$port_key]"
  done
}
