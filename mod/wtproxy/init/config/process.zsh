# wtproxyの初期設定ファイルの内容を組み立てる
#
# $@: 名前付きの設定値
# REPLY: 設定ファイルの内容
# return: null
#
# example:
#  z.wtproxy.init._config.content proxy_port_1=3000
z.wtproxy.init._config.content() {
  local -a lines=()
  z.wtproxy.init._config.port.keys "$@"
  local -a keys=("${(@)REPLY}")

  for key in $keys; do
    z.wtproxy.init._config.port.value $key "$@"
    local value=$REPLY
    z.is.null "$value" && continue

    z.wtproxy._port.proxy.env.key $key
    local env_name=$REPLY

    lines+=("$env_name=$value")
  done

  REPLY="${(F)lines}"$'\n'
}

# wtproxyの初期設定ファイルを作成する
#
# $force?: trueなら既存ファイルを上書きする
# $@: 名前付きの設定値
# REPLY: null
# return: ファイルを作成できた場合は0、それ以外は1
#
# example:
#  z.wtproxy.init._config.file proxy_port_1=3000
z.wtproxy.init._config.file() {
  z.arg.named force $@ default=false
  local force=$REPLY

  z.wtproxy._config.file.path
  local file=$REPLY

  if z.is.null $file; then
    z.io.error "git worktree root is required"
    return 1
  fi

  if z.file.exists $file && ! z.is.true $force; then
    z.io.error "$file already exists"
    return 1
  fi

  z.wtproxy.init._config.content "$@"
  local content=$REPLY

  z.file.make path=$file with_dir=true
  z.file.write path=$file content="$content"

  z.io "created: $file"
}
