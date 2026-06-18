# get the default wtproxy configuration file path
#
# REPLY: configuration file path|null
# return: null
#
# example:
#  z.wtproxy._config.file.path
z.wtproxy._config.file.path() {
  z.wtproxy._config.file.default_project || { z.return; return; }
  local project=$REPLY
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

  z.return "$config_home/$z_wtproxy_config_dir_name/$project.$z_wtproxy_config_file_extension"
}

# get the configuration key for an environment variable name
#
# $1: environment variable name
# REPLY: configuration key|null
# return: null
#
# example:
#  z.wtproxy._config.file.key Z_WTPROXY_PROXY_PORT_1
z.wtproxy._config.file.key() {
  local env_name=$1

  z.wtproxy._port.proxy.env.index $env_name || { z.return; return; }
  local port_index=$REPLY

  z.wtproxy._port.proxy.key $port_index
}

# parse a wtproxy configuration file line
#
# $1: configuration file line
# REPLY: configuration key and value|null
# return: 0 if the line contains a known setting, otherwise 1
#
# example:
#  z.wtproxy._config.file.line "Z_WTPROXY_PROXY_PORT_1=3000"
z.wtproxy._config.file.line() {
  local line=$1
  z.str.trim "$line"
  line=$REPLY

  z.is.null "$line" && return 1
  z.guard "comment line"; {
    z.str.start_with "$line" "#" && return 1
  }
  if z.str.start_with "$line" "export "; then
    z.str.match.rest "$line" "export "
    line=$REPLY
    z.str.trim "$line"
    line=$REPLY
  fi

  z.str.includes "$line" "=" || return 1

  local env_name=${line%%=*}
  local value=${line#*=}

  z.str.trim "$env_name"
  env_name=$REPLY
  z.str.trim "$value"
  value=$REPLY

  z.wtproxy._config.file.key $env_name
  local key=$REPLY

  z.is.null $key && return 1

  z.return "$key" "$value" keep_empty=true
}

# get wtproxy configuration values from the configuration file
#
# REPLY: configuration hash as key-value pairs
# return: null
#
# example:
#  z.wtproxy._config.file.values
z.wtproxy._config.file.values() {
  local -A config=()

  z.wtproxy._config.file.path
  local file=$REPLY
  if z.is.null $file || z.file.not.exists $file; then
    z.return.hash config
    return
  fi

  while IFS= read -r line || [[ -n $line ]]; do
    z.wtproxy._config.file.line "$line" || continue
    local -a entry=("${(@)REPLY}")
    config[$entry[1]]=$entry[2]
  done < "$file"

  z.return.hash config
}

# infer the default wtproxy project name
#
# REPLY: project name
# return: null
#
# example:
#  z.wtproxy._config.file.default_project
z.wtproxy._config.file.default_project() {
  z.git.wt.current.common_dir || {
    z.return
    return 1
  }
  local common_dir=$REPLY

  z.path.dir "$common_dir"
  z.path.base "$REPLY"
  local project=$REPLY

  z.wtproxy._slug "$project"
}
