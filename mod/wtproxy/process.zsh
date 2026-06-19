# show wtproxy status
#
# REPLY: null
# return: null
#
# example:
#  z.wtproxy
z.wtproxy() {
  z.wtproxy.status
}

# show wtproxy help
#
# REPLY: null
# return: null
#
# example:
#  z.wtproxy.help
z.wtproxy.help() {
  z.io.empty
  z.io indent=1 "Usage:"
  z.io indent=2 "init:    z.wtproxy.init ?proxy_port_N=<port> ?force=true"
  z.io indent=3 "create the config file"
  z.io indent=2 "env:     z.wtproxy.env ?command..."
  z.io indent=3 "print env assignments or run command with them"
  z.io indent=2 "use:     z.wtproxy.use"
  z.io indent=3 "activate the current worktree"
  z.io indent=2 "start:   z.wtproxy.start"
  z.io indent=3 "activate the current worktree and start the proxy daemon"
  z.io indent=2 "status:  z.wtproxy.status"
  z.io indent=3 "show active entry and proxy daemon status"
  z.io indent=2 "stop:    z.wtproxy.stop"
  z.io indent=3 "stop the proxy daemon"
  z.io indent=2 "rm:      z.wtproxy.rm"
  z.io indent=3 "remove the current entry and its Docker resources"
  z.io indent=2 "prune:   z.wtproxy.prune"
  z.io indent=3 "remove stale entries and their Docker resources"
  z.io.line
  z.io indent=1 "Workflow:"
  z.io indent=2 "1. z.wtproxy.init"
  z.io indent=2 "2. z.wtproxy.use or z.wtproxy.start"
  z.io indent=2 "3. z.wtproxy.env docker compose up"
  z.io.line
  z.io indent=1 "Notes:"
  z.io indent=2 "rm/prune remove Docker images and volumes for the stored compose project."
  z.io.line
  z.io indent=1 "Environment:"
  z.io indent=2 "proxy:   Z_WTPROXY_PROXY_PORT_N"
  z.io indent=2 "worktree: Z_WTPROXY_WORKTREE_PORT_N"
  z.io indent=2 "compose: COMPOSE_PROJECT_NAME"
  z.io.line
  z.io indent=1 "Files:"
  z.io indent=2 "config:  \${XDG_CONFIG_HOME:-\$HOME/.config}/wtproxy/<project>.env"
  z.io indent=2 "state:   \${XDG_STATE_HOME:-\$HOME/.local/state}/wtproxy/<project>.state"
}

# create the initial wtproxy configuration file
#
# $@: named configuration values
# REPLY: null
# return: 0 if the file is created, otherwise 1
#
# example:
#  z.wtproxy.init
z.wtproxy.init() {
  z.wtproxy.init._config.file "$@"
}

# print Docker Compose environment values or run a command with them
#
# $@?: command to run with environment values
# REPLY: null
# return: command status if a command is given, 0 if printed, otherwise 1
#
# example:
#  z.wtproxy.env
#  z.wtproxy.env docker compose up
z.wtproxy.env() {
  z.wtproxy._entry.current || return 1
  local -A entry=("${(@)REPLY}")
  local -a env_values=(
    "COMPOSE_PROJECT_NAME=$entry[compose_project_name]"
  )

  z.wtproxy._port.keys || return 1
  for port_key in ${(@)REPLY}; do
    z.wtproxy._port.worktree.index $port_key
    local port_index=$REPLY
    env_values+=("$z_wtproxy_worktree_port_env_prefix$port_index=$entry[$port_key]")
  done

  z.arr.count "$@"
  if z.int.is.gt $REPLY 0; then
    (
      export "${env_values[@]}"
      "$@"
    )
    return $?
  fi

  z.io.line ${env_values[@]}
}

# activate current worktree and print its proxy entry
#
# REPLY: null
# return: 0 if current entry is available, otherwise 1
#
# example:
#  z.wtproxy.use
z.wtproxy.use() {
  z.wtproxy._entry.current activate=true || return 1
  z.wtproxy._print.entry "${(@)REPLY}"
}

# activate current worktree and start proxy daemon
#
# REPLY: null
# return: 0 if proxy is started, otherwise 1
#
# example:
#  z.wtproxy.start
z.wtproxy.start() {
  z.wtproxy._entry.current activate=true || return 1
  local -A entry=("${(@)REPLY}")
  z.wtproxy.start._daemon || return 1
  z.wtproxy._print.entry "${(@kv)entry}"
}

# stop proxy daemon
#
# REPLY: null
# return: null
#
# example:
#  z.wtproxy.stop
z.wtproxy.stop() {
  if z.wtproxy.stop._daemon; then
    z.io "stopped"
  else
    z.io "not running"
  fi
}

# print active entry and proxy daemon status
#
# REPLY: null
# return: null
#
# example:
#  z.wtproxy.status
z.wtproxy.status() {
  if z.wtproxy._entry.active; then
    z.wtproxy._print.entry "${(@)REPLY}"
  else
    z.io "active: none"
  fi

  if z.wtproxy._proxy.is.running; then
    z.io "proxy: running"
  else
    z.io "proxy: stopped"
  fi
}

# remove current worktree entry and its Docker resources
#
# REPLY: null
# return: 0 if current entry is removed, otherwise 1
#
# example:
#  z.wtproxy.rm
z.wtproxy.rm() {
  z.wtproxy.rm._current.entry || return 1
  local -A entry=("${(@)REPLY}")

  local project_name=$entry[compose_project_name]
  if z.is.not.null "$project_name"; then
    z.wtproxy._docker.prune "$project_name" || return 1
  fi

  z.wtproxy.rm._current expected_project="$project_name" || return 1
  local -A result=("${(@)REPLY}")

  z.io "removed: $result[removed_path]"
  z.io "entries: $result[entries_count]"
  if z.is.not.null "$result[removed_project]"; then
    z.io "docker_resource_project: $result[removed_project]"
  fi
}

# remove stale worktree entries from state
#
# REPLY: null
# return: 0 if state is updated, otherwise 1
#
# example:
#  z.wtproxy.prune
z.wtproxy.prune() {
  z.wtproxy.prune._stale || return 1
  local -A result=("${(@)REPLY}")

  z.io "entries: $result[entries_count]"
  if z.is.not.null "$result[pruned_projects]"; then
    z.io "docker_resource_projects: $result[pruned_projects]"
  fi
}
