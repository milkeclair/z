# プロキシエントリを表示する
#
# $@: エントリのキーと値の組
# REPLY: null
# return: 設定を取得できた場合は0、それ以外は1
#
# example:
#  # proxy_port_1=3000だけが有効な設定の場合
#  local -A entry=(path /tmp/worktree branch feat/example compose_project_name sample_feat_example_b671591e worktree_port_1 3001)
#  z.wtproxy._print.entry "${(@kv)entry}"
#  # 出力:
#  # path: /tmp/worktree
#  # branch: feat/example
#  # compose_project_name: sample_feat_example_b671591e
#  # worktree_port_1: 127.0.0.1:3000 -> 127.0.0.1:3001
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
