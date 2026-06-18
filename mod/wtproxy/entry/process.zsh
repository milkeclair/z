# ensure entry for the current worktree
#
# $activate?: set current worktree as active(default: false)
# REPLY: entry hash as key-value pairs
# return: 0 if entry is available, otherwise 1
#
# example:
#  z.wtproxy._entry.current activate=true
z.wtproxy._entry.current() {
  z.arg.named activate $@ default=false && local activate=$REPLY

  z.git.wt.current.root || return 1
  local worktree_path=$REPLY
  z.git.branch.label.current || return 1
  local branch=$REPLY

  z.wtproxy._state.with_lock z.wtproxy._entry.current.locked "$worktree_path" "$branch" "$activate"
}

# read active worktree entry
#
# REPLY: entry hash as key-value pairs
# return: 0 if active entry is available, otherwise 1
#
# example:
#  z.wtproxy._entry.active
z.wtproxy._entry.active() {
  z.wtproxy._state.with_lock z.wtproxy._entry.active.locked
}

# ensure an entry exists in loaded state
#
# $1: worktree path
# $2: branch label
# REPLY: entry hash as key-value pairs
# return: 0 if entry is available, otherwise 1
#
# example:
#  z.wtproxy._entry.ensure /path/to/worktree feat/example
z.wtproxy._entry.ensure() {
  local worktree_path=$1
  local branch=$2

  if ! z.wtproxy._state.path.has "$worktree_path"; then
    z_wtproxy_state_paths+=($worktree_path)
  fi

  z.wtproxy._port.keys || return 1
  for port_key in ${(@)REPLY}; do
    z.wtproxy._state.port.get "$worktree_path" "$port_key"
    if z.is.null $REPLY; then
      z.wtproxy._port.allocate "$worktree_path" "$port_key" || return 1
      z.wtproxy._state.port.set "$worktree_path" "$port_key" "$REPLY"
    fi
  done

  if z.is.null $z_wtproxy_state_compose[$worktree_path]; then
    z.wtproxy._entry.compose.name "$branch" || return 1
    z_wtproxy_state_compose[$worktree_path]=$REPLY
  fi

  z_wtproxy_state_branch[$worktree_path]=$branch
  z.wtproxy._state.entry "$worktree_path"
}
