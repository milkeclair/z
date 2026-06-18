# show wt_proxy status
#
# REPLY: null
# return: null
#
# example:
#  z.wt_proxy
z.wt_proxy() {
  z.wt_proxy.status
}

# show wt_proxy help
#
# REPLY: null
# return: null
#
# example:
#  z.wt_proxy.help
z.wt_proxy.help() {
  z.io.empty
  z.io indent=1 "Usage:"
  z.io indent=2 "init:    z.wt_proxy.init ?proxy_port_N=<port> ?force=true"
  z.io indent=3 "create the config file"
  z.io indent=2 "env:     z.wt_proxy.env ?command..."
  z.io indent=3 "print env assignments or run command with them"
  z.io indent=2 "use:     z.wt_proxy.use"
  z.io indent=3 "activate the current worktree"
  z.io indent=2 "start:   z.wt_proxy.start"
  z.io indent=3 "activate the current worktree and start the proxy daemon"
  z.io indent=2 "status:  z.wt_proxy.status"
  z.io indent=3 "show active entry and proxy daemon status"
  z.io indent=2 "stop:    z.wt_proxy.stop"
  z.io indent=3 "stop the proxy daemon"
  z.io indent=2 "rm:      z.wt_proxy.rm"
  z.io indent=3 "remove the current entry and its Docker resources"
  z.io indent=2 "prune:   z.wt_proxy.prune"
  z.io indent=3 "remove stale entries and their Docker resources"
  z.io.line
  z.io indent=1 "Workflow:"
  z.io indent=2 "1. z.wt_proxy.init"
  z.io indent=2 "2. z.wt_proxy.use or z.wt_proxy.start"
  z.io indent=2 "3. z.wt_proxy.env docker compose up"
  z.io.line
  z.io indent=1 "Notes:"
  z.io indent=2 "rm/prune remove Docker images and volumes for the stored compose project."
  z.io.line
  z.io indent=1 "Environment:"
  z.io indent=2 "proxy:   Z_WT_PROXY_PROXY_PORT_N"
  z.io indent=2 "worktree: Z_WT_PROXY_WORKTREE_PORT_N"
  z.io indent=2 "compose: COMPOSE_PROJECT_NAME"
  z.io.line
  z.io indent=1 "Files:"
  z.io indent=2 "config:  \${XDG_CONFIG_HOME:-\$HOME/.config}/worktree-proxy/<project>.env"
  z.io indent=2 "state:   \${XDG_STATE_HOME:-\$HOME/.local/state}/worktree-proxy/<project>.state"
}

# create the initial wt_proxy configuration file
#
# $@: named configuration values
# REPLY: null
# return: 0 if the file is created, otherwise 1
#
# example:
#  z.wt_proxy.init
z.wt_proxy.init() {
  z.wt_proxy.init._config.file "$@"
}

# print Docker Compose environment values or run a command with them
#
# $@?: command to run with environment values
# REPLY: null
# return: command status if a command is given, 0 if printed, otherwise 1
#
# example:
#  z.wt_proxy.env
#  z.wt_proxy.env docker compose up
z.wt_proxy.env() {
  z.wt_proxy._entry.current || return 1
  local -A entry=("${(@)REPLY}")
  local -a env_values=(
    "COMPOSE_PROJECT_NAME=$entry[compose_project_name]"
  )

  z.wt_proxy._port.keys || return 1
  for port_key in ${(@)REPLY}; do
    z.wt_proxy._port.worktree.index $port_key
    local port_index=$REPLY
    env_values+=("$z_wt_proxy_worktree_port_env_prefix$port_index=$entry[$port_key]")
  done

  if z.is.not.null "$@"; then
    env "${env_values[@]}" "$@"
    return $?
  fi

  print -r -- "${(F)env_values}"
}

# activate current worktree and print its proxy entry
#
# REPLY: null
# return: 0 if current entry is available, otherwise 1
#
# example:
#  z.wt_proxy.use
z.wt_proxy.use() {
  z.wt_proxy._entry.current activate=true || return 1
  z.wt_proxy._print.entry "${(@)REPLY}"
}

# activate current worktree and start proxy daemon
#
# REPLY: null
# return: 0 if proxy is started, otherwise 1
#
# example:
#  z.wt_proxy.start
z.wt_proxy.start() {
  z.wt_proxy._entry.current activate=true || return 1
  local -A entry=("${(@)REPLY}")
  z.wt_proxy.start._daemon || return 1
  z.wt_proxy._print.entry "${(@kv)entry}"
}

# stop proxy daemon
#
# REPLY: null
# return: null
#
# example:
#  z.wt_proxy.stop
z.wt_proxy.stop() {
  if z.wt_proxy.stop._daemon; then
    print -r -- "stopped"
  else
    print -r -- "not running"
  fi
}

# print active entry and proxy daemon status
#
# REPLY: null
# return: null
#
# example:
#  z.wt_proxy.status
z.wt_proxy.status() {
  if z.wt_proxy._entry.active; then
    z.wt_proxy._print.entry "${(@)REPLY}"
  else
    print -r -- "active: none"
  fi

  if z.wt_proxy._proxy.is.running; then
    print -r -- "proxy: running"
  else
    print -r -- "proxy: stopped"
  fi
}

# remove current worktree entry and its Docker resources
#
# REPLY: null
# return: 0 if current entry is removed, otherwise 1
#
# example:
#  z.wt_proxy.rm
z.wt_proxy.rm() {
  z.wt_proxy.rm._current.entry || return 1
  local -A entry=("${(@)REPLY}")

  local project_name=$entry[compose_project_name]
  if z.is.not.null "$project_name"; then
    z.wt_proxy._docker.prune "$project_name" || return 1
  fi

  z.wt_proxy.rm._current expected_project="$project_name" || return 1
  local -A result=("${(@)REPLY}")

  print -r -- "removed: $result[removed_path]"
  print -r -- "entries: $result[entries_count]"
  if z.is.not.null "$result[removed_project]"; then
    print -r -- "docker_resource_project: $result[removed_project]"
  fi
}

# remove stale worktree entries from state
#
# REPLY: null
# return: 0 if state is updated, otherwise 1
#
# example:
#  z.wt_proxy.prune
z.wt_proxy.prune() {
  z.wt_proxy.prune._stale || return 1
  local -A result=("${(@)REPLY}")
  local pruned_project_names=$result[pruned_projects]

  for project_name in ${(z)pruned_project_names}; do
    z.wt_proxy._docker.prune "$project_name" || return 1
  done

  print -r -- "entries: $result[entries_count]"
  if z.is.not.null "$result[pruned_projects]"; then
    print -r -- "docker_resource_projects: $result[pruned_projects]"
  fi
}
