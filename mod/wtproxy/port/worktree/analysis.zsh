# get the worktree port key from the index
#
# $1: port index
# REPLY: worktree port key
# return: null
#
# example:
#  z.wtproxy._port.worktree.key 1
z.wtproxy._port.worktree.key() {
  local port_index=$1

  z.return "$z_wtproxy_worktree_port_key_prefix$port_index"
}

# get the index from the worktree port key
#
# $1: worktree port key
# REPLY: port index|null
# return: 0 if the key is a numbered worktree port key, otherwise 1
#
# example:
#  z.wtproxy._port.worktree.index worktree_port_1
z.wtproxy._port.worktree.index() {
  local key=$1

  if z.str.is.match "$key" "${z_wtproxy_worktree_port_key_prefix}<->"; then
    z.return ${key#$z_wtproxy_worktree_port_key_prefix}
    return
  fi

  z.return
  return 1
}
