# wtproxyの既定の設定ファイルパスを取得する
#
# REPLY: 設定ファイルのパス|null
# return: null
#
# example:
#  # Gitプロジェクト名がsampleの場合
#  local XDG_CONFIG_HOME=/tmp/config
#  z.wtproxy._config.file.path
#  # REPLY: "/tmp/config/wtproxy/sample.env"
z.wtproxy._config.file.path() {
  z.wtproxy._config.file.default_project || { REPLY=""; return; }
  local project=$REPLY
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

  REPLY="$config_home/$z_wtproxy_config_dir_name/$project.$z_wtproxy_config_file_extension"
}

# 環境変数名に対応する設定キーを取得する
#
# $1: 環境変数名
# REPLY: 設定キー|null
# return: null
#
# example:
#  z.wtproxy._config.file.key Z_WTPROXY_PROXY_PORT_1
#  # REPLY: "proxy_port_1"
z.wtproxy._config.file.key() {
  local env_name=$1

  z.wtproxy._port.proxy.env.index $env_name || { REPLY=""; return; }
  local port_index=$REPLY

  z.wtproxy._port.proxy.key $port_index
}

# wtproxy設定ファイルの1行を解析する
#
# $1: 設定ファイルの行
# REPLY: 設定のキーと値|null
# return: 行に既知の設定が含まれる場合は0、それ以外は1
#
# example:
#  z.wtproxy._config.file.line "Z_WTPROXY_PROXY_PORT_1=3000"
#  # REPLY: ("proxy_port_1" "3000")
#  # return: 0
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

  z.str.partition "$line" "=" literal=true
  local -a config_line=("${(@)REPLY}")
  local env_name=$config_line[1]
  local value=$config_line[2]

  z.str.trim "$env_name"
  env_name=$REPLY
  z.str.trim "$value"
  value=$REPLY

  z.wtproxy._config.file.key $env_name
  local key=$REPLY

  z.is.null $key && return 1

  REPLY=("$key" "$value")
}

# 設定ファイルからwtproxyの設定値を取得する
#
# REPLY: 設定のキーと値の組
# return: null
#
# example:
#  # 設定ファイルの内容がZ_WTPROXY_PROXY_PORT_1=3000の1行だけの場合
#  z.wtproxy._config.file.values
#  # REPLY: ("proxy_port_1" "3000")
z.wtproxy._config.file.values() {
  local -A config=()

  z.wtproxy._config.file.path
  local file=$REPLY
  if z.is.null $file || z.file.not.exists $file; then
    z.hash.entries config
    return
  fi

  while IFS= read -r line || [[ -n $line ]]; do
    z.wtproxy._config.file.line "$line" || continue
    local -a entry=("${(@)REPLY}")
    config[$entry[1]]=$entry[2]
  done < "$file"

  z.hash.entries config
}

# wtproxyの既定のプロジェクト名を推定する
#
# REPLY: プロジェクト名
# return: null
#
# example:
#  # Gitの共通ディレクトリが/tmp/sample/.gitの場合
#  z.wtproxy._config.file.default_project
#  # REPLY: "sample"
z.wtproxy._config.file.default_project() {
  z.git.wt.current.common_dir || {
    REPLY=""
    return 1
  }
  local common_dir=$REPLY

  z.path.dir "$common_dir"
  z.path.base "$REPLY"
  local project=$REPLY

  z.wtproxy._slug "$project"
}
