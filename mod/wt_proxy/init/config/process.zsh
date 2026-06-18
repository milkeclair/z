# build the wt_proxy initial configuration file content
#
# $@: named configuration values
# REPLY: configuration file content
# return: null
#
# example:
#  z.wt_proxy.init._config.content proxy_port_1=3000
z.wt_proxy.init._config.content() {
  local -a lines=()
  z.wt_proxy.init._config.port.keys "$@"
  local -a keys=("${(@)REPLY}")

  for key in $keys; do
    z.wt_proxy.init._config.port.value $key "$@"
    local value=$REPLY
    z.is.null "$value" && continue

    z.wt_proxy._port.proxy.env.key $key
    local env_name=$REPLY

    lines+=("$env_name=$value")
  done

  z.return "${(F)lines}"$'\n'
}

# create the initial wt_proxy configuration file
#
# $force?: overwrite existing file when true
# $@: named configuration values
# REPLY: null
# return: 0 if the file is created, otherwise 1
#
# example:
#  z.wt_proxy.init._config.file proxy_port_1=3000
z.wt_proxy.init._config.file() {
  z.arg.named force $@ default=false
  local force=$REPLY

  z.wt_proxy._config.file.path
  local file=$REPLY

  if z.is.null $file; then
    z.io.error "git worktree root is required"
    return 1
  fi

  if z.file.exists $file && ! z.is.true $force; then
    z.io.error "$file already exists"
    return 1
  fi

  z.wt_proxy.init._config.content "$@"
  local content=$REPLY

  z.file.make path=$file with_dir=true
  z.file.write path=$file content="$content"

  print -r -- "created: $file"
}
