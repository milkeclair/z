# initialize in-memory wtproxy state
#
# REPLY: null
# return: null
#
# example:
#  z.wtproxy._state.init
z.wtproxy._state.init() {
  typeset -g z_wtproxy_state_active_path=""
  typeset -ga z_wtproxy_state_paths=()
  typeset -gA z_wtproxy_state_branch=()
  typeset -gA z_wtproxy_state_compose=()
  typeset -gA z_wtproxy_state_port=()
}

# load wtproxy state from the state file
#
# REPLY: null
# return: 0 if state is loaded, otherwise 1
#
# example:
#  z.wtproxy._state.load
z.wtproxy._state.load() {
  z.wtproxy._state.init
  z.wtproxy._config.value state_file || return 1
  local state_file=$REPLY
  z.file.not.exists $state_file && return 0

  while IFS= read -r line || [[ -n $line ]]; do
    local words=("${(@)${(z)line}}")
    local kind=$words[1]

    if z.is.eq $kind active; then
      z_wtproxy_state_active_path=${(Q)words[2]}
      continue
    fi

    if z.is.eq $kind entry; then
      local worktree_path=${(Q)words[2]}
      z_wtproxy_state_paths+=($worktree_path)
      z_wtproxy_state_branch[$worktree_path]=${(Q)words[3]}
      z_wtproxy_state_compose[$worktree_path]=${(Q)words[4]}

      local word_index
      for ((word_index=5; word_index<=${#words[@]}; word_index++)); do
        local port_entry=$words[$word_index]
        z.str.includes "$port_entry" "=" || continue

        z.str.split str="$port_entry" delimiter="="
        local port_key=$REPLY[1]
        local port=$REPLY[2]
        z.wtproxy._state.port.set "$worktree_path" "$port_key" "$port"
      done
    fi
  done < $state_file
}

# save wtproxy state to the state file
#
# REPLY: null
# return: 0 if state is saved, otherwise 1
#
# example:
#  z.wtproxy._state.save
z.wtproxy._state.save() {
  z.wtproxy._config || return 1
  local -A config=("${(@)REPLY}")

  z.dir.make path=$config[state_dir]

  {
    print -r -- "active ${(qqq)z_wtproxy_state_active_path}"
    for worktree_path in $z_wtproxy_state_paths; do
      local port_entries=()
      z.wtproxy._port.keys

      for port_key in ${(@)REPLY}; do
        z.wtproxy._state.port.get "$worktree_path" "$port_key"
        local port=$REPLY
        z.is.not.null "$port" && port_entries+=("$port_key=$port")
      done

      local entry_fields=(
        entry
        ${(qqq)worktree_path}
        ${(qqq)z_wtproxy_state_branch[$worktree_path]}
        ${(qqq)z_wtproxy_state_compose[$worktree_path]}
      )
      print -r -- ${entry_fields[@]} ${port_entries[@]}
    done
  } >! $config[state_file]

  z.perm path=$config[state_file] mode=600
}

# run a function while holding the state lock
#
# $1: function name
# $@?: function arguments
# REPLY: function return value
# return: function return status
#
# example:
#  z.wtproxy._state.with_lock z.wtproxy._entry.current.locked "$path" "$branch" true
z.wtproxy._state.with_lock() {
  local fn=$1
  shift

  z.wtproxy._config || return 1
  local -A config=("${(@)REPLY}")

  z.dir.make path=$config[state_dir]
  z.file.make path=$config[lock_file] with_dir=true

  zmodload zsh/system
  local lock_fd
  zsystem flock -f lock_fd $config[lock_file] || return 1

  $fn "$@"
  local exit_status=$?

  zsystem flock -u $lock_fd
  return $exit_status
}
