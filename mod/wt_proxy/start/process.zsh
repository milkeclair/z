# start proxy daemon for z.wt_proxy.start
#
# REPLY: null
# return: 0 if daemon is running, otherwise 1
#
# example:
#  z.wt_proxy.start._daemon
z.wt_proxy.start._daemon() {
  z.wt_proxy._proxy.is.running && return 0

  z.wt_proxy._config || return 1
  local -A config=("${(@)REPLY}")
  z.dir.make path=$config[state_dir]
  z.file.make path=$config[log_file] with_dir=true

  # disownで切り離す
  Z_ROOT=$z_root command zsh -fc 'source "$Z_ROOT/main.zsh" && z.wt_proxy.start._serve' </dev/null >>$config[log_file] 2>&1 &!
  local pid=$!
  print -r -- $pid >! $config[pid_file]
  sleep 0.3

  z.wt_proxy._proxy.is.pid "$pid" && return 0

  rm -f "$config[pid_file]"
  z.io.error "Proxy failed to start. See $config[log_file]"
  return 1
}

# serve proxy listeners in the current process
#
# REPLY: null
# return: 0 if proxy exits normally, otherwise 1
#
# example:
#  z.wt_proxy.start._serve
z.wt_proxy.start._serve() {
  zmodload zsh/net/tcp
  zmodload zsh/zselect
  zmodload zsh/system

  z.wt_proxy._config || return 1
  local -A config=("${(@)REPLY}")
  z.dir.make path=$config[state_dir]
  print -r -- $$ >! $config[pid_file]

  local -A listener_keys=()
  local listener_fds=()

  z.wt_proxy._port.keys.from_config config
  for port_key in ${(@)REPLY}; do
    z.wt_proxy._port.proxy $port_key || return 1
    local proxy_port=$REPLY
    ztcp -l $proxy_port || return 1
    local listener_fd=$REPLY
    listener_keys[$listener_fd]=$port_key
    listener_fds+=($listener_fd)
  done

  trap "z.wt_proxy.start._serve.cleanup ${(j: :)listener_fds}; exit 0" INT TERM
  trap "z.wt_proxy.start._serve.cleanup ${(j: :)listener_fds}" EXIT

  while true; do
    local -A ready=()
    zselect -A ready $listener_fds || continue

    for listener_fd in ${(k)ready}; do
      z.wt_proxy.start._serve.accept "$listener_fd" "$listener_keys[$listener_fd]"
    done
  done
}
