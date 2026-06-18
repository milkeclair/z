# get the default wt_proxy configuration file path
#
# REPLY: configuration file path|null
# return: null
#
# example:
#  z.wt_proxy._config.file.path
z.wt_proxy._config.file.path() {
  z.wt_proxy._config.file.default_project || { z.return; return; }
  local project=$REPLY
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

  z.return "$config_home/$z_wt_proxy_config_dir_name/$project.$z_wt_proxy_config_file_extension"
}

# get the configuration key for an environment variable name
#
# $1: environment variable name
# REPLY: configuration key|null
# return: null
#
# example:
#  z.wt_proxy._config.file.key Z_WT_PROXY_PROXY_PORT_1
z.wt_proxy._config.file.key() {
  local env_name=$1

  z.wt_proxy._port.proxy.env.index $env_name || { z.return; return; }
  local port_index=$REPLY

  z.wt_proxy._port.proxy.key $port_index
}

# parse a wt_proxy configuration file line
#
# $1: configuration file line
# REPLY: configuration key and value|null
# return: 0 if the line contains a known setting, otherwise 1
#
# example:
#  z.wt_proxy._config.file.line "Z_WT_PROXY_PROXY_PORT_1=3000"
z.wt_proxy._config.file.line() {
  local line=$1
  z.str.trim "$line"
  line=$REPLY

  z.is.null "$line" && return 1
  z.guard "comment line"; {
    z.str.start_with "$line" "#" && return 1
  }
  if z.str.start_with "$line" "export "; then
    line=${line#export }
    z.str.trim "$line"
    line=$REPLY
  fi

  [[ $line == *=* ]] || return 1

  local env_name=${line%%=*}
  local value=${line#*=}

  z.str.trim "$env_name"
  env_name=$REPLY
  z.str.trim "$value"
  value=$REPLY

  z.wt_proxy._config.file.key $env_name
  local key=$REPLY

  z.is.null $key && return 1

  z.return "$key" "$value" keep_empty=true
}

# get wt_proxy configuration values from the configuration file
#
# REPLY: configuration hash as key-value pairs
# return: null
#
# example:
#  z.wt_proxy._config.file.values
z.wt_proxy._config.file.values() {
  local -A config=()

  z.wt_proxy._config.file.path
  local file=$REPLY
  if z.is.null $file || z.file.not.exists $file; then
    z.return.hash config
    return
  fi

  while IFS= read -r line || [[ -n $line ]]; do
    z.wt_proxy._config.file.line "$line" || continue
    local -a entry=("${(@)REPLY}")
    config[$entry[1]]=$entry[2]
  done < "$file"

  z.return.hash config
}

# infer the default wt_proxy project name
#
# REPLY: project name
# return: null
#
# example:
#  z.wt_proxy._config.file.default_project
z.wt_proxy._config.file.default_project() {
  z.git.wt.current.root >/dev/null 2>&1 || {
    z.return
    return 1
  }
  local root=$REPLY
  local root_name=${root:t}
  local parent_name=${root:h:t}
  local project=$root_name

  if z.str.end_with "$parent_name" "_worktree"; then
    project=${parent_name%_worktree}
  fi

  z.wt_proxy._slug "$project"
}
