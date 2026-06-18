# get wtproxy configuration
#
# REPLY: configuration hash as key-value pairs
# return: null
#
# example:
#  z.wtproxy._config
z.wtproxy._config() {
  z.wtproxy._config.values || return 1
  local -A config=("${(@)REPLY}")

  z.wtproxy._config.file.default_project || {
    z.io.error "git worktree root is required"
    return 1
  }
  config[project]=$REPLY

  local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/$z_wtproxy_state_dir_name"

  config[host]=$z_wtproxy_host
  config[state_dir]=$state_dir
  config[state_file]="$state_dir/$config[project].state"
  config[lock_file]="$state_dir/$config[project].lock"
  config[pid_file]="$state_dir/$config[project].pid"
  config[log_file]="$state_dir/$config[project].log"

  z.return.hash config
}

# get a single wtproxy configuration value
#
# $1: configuration key
# REPLY: configuration value
# return: 0 if configuration is available, otherwise 1
#
# example:
#  z.wtproxy._config.value state_file
z.wtproxy._config.value() {
  local key=$1

  z.wtproxy._config || return 1
  local -A config=("${(@)REPLY}")
  z.return "$config[$key]"
}

# get wtproxy configuration values from defaults, file settings, and environment
#
# REPLY: configuration hash as key-value pairs
# return: null
#
# example:
#  z.wtproxy._config.values
z.wtproxy._config.values() {
  local -A config=("${(@kv)z_wtproxy_default_config_values}")

  z.wtproxy._config.file.values
  local -A file_config=("${(@)REPLY}")

  z.hash.merge base=config other=file_config
  config=("${(@)REPLY}")

  # envがconfig fileより優先
  z.wtproxy._config.port.env.values
  local -A env_config=("${(@)REPLY}")

  z.hash.merge base=config other=env_config
  config=("${(@)REPLY}")

  z.return.hash config
}
