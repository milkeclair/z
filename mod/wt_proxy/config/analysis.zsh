# get wt_proxy configuration
#
# REPLY: configuration hash as key-value pairs
# return: null
#
# example:
#  z.wt_proxy._config
z.wt_proxy._config() {
  z.wt_proxy._config.values || return 1
  local -A config=("${(@)REPLY}")

  z.wt_proxy._config.file.default_project || {
    z.io.error "git worktree root is required"
    return 1
  }
  config[project]=$REPLY

  local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/$z_wt_proxy_state_dir_name"

  config[host]=$z_wt_proxy_host
  config[state_dir]=$state_dir
  config[state_file]="$state_dir/$config[project].state"
  config[lock_file]="$state_dir/$config[project].lock"
  config[pid_file]="$state_dir/$config[project].pid"
  config[log_file]="$state_dir/$config[project].log"

  z.return.hash config
}

# get a single wt_proxy configuration value
#
# $1: configuration key
# REPLY: configuration value
# return: 0 if configuration is available, otherwise 1
#
# example:
#  z.wt_proxy._config.value state_file
z.wt_proxy._config.value() {
  local key=$1

  z.wt_proxy._config || return 1
  local -A config=("${(@)REPLY}")
  z.return "$config[$key]"
}

# get wt_proxy configuration values from defaults, file settings, and environment
#
# REPLY: configuration hash as key-value pairs
# return: null
#
# example:
#  z.wt_proxy._config.values
z.wt_proxy._config.values() {
  local -A config=("${(@kv)z_wt_proxy_default_config_values}")

  z.wt_proxy._config.file.values
  local -A file_config=("${(@)REPLY}")

  for key in ${(k)file_config}; do
    config[$key]=$file_config[$key]
  done

  # envがconfig fileより優先
  z.wt_proxy._config.port.env.values
  local -A env_config=("${(@)REPLY}")

  for key in ${(k)env_config}; do
    config[$key]=$env_config[$key]
  done

  z.return.hash config
}
