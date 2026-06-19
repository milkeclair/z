# start proxy daemon for z.wtproxy.start
#
# REPLY: null
# return: 0 if daemon is running, otherwise 1
#
# example:
#  z.wtproxy.start._daemon
z.wtproxy.start._daemon() {
  z.wtproxy._proxy.is.running && return 0

  z.wtproxy._config || return 1
  local -A config=("${(@)REPLY}")
  z.dir.make path=$config[state_dir]
  z.file.make path=$config[log_file] with_dir=true

  # disownで切り離す
  Z_ROOT=$z_root command zsh -fc 'source "$Z_ROOT/main.zsh" && z.wtproxy.start._serve' </dev/null >>$config[log_file] 2>&1 &!
  local pid=$!
  z.file.write path=$config[pid_file] content=$pid
  sleep 0.3

  z.wtproxy._proxy.is.pid "$pid" && return 0

  z.io.null kill -TERM "$pid"
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
#  z.wtproxy.start._serve
z.wtproxy.start._serve() {
  zmodload zsh/net/tcp
  zmodload zsh/zselect
  zmodload zsh/system

  z.wtproxy._config || return 1
  local -A config=("${(@)REPLY}")
  z.dir.make path=$config[state_dir]
  z.file.write path=$config[pid_file] content=$$

  local -A listener_keys=()
  local listener_fds=()
  typeset -g z_wtproxy_serve_state_file=$config[state_file]
  typeset -g z_wtproxy_serve_active_line=""
  typeset -ga z_wtproxy_serve_active_entry=()
  typeset -ga z_wtproxy_serve_pipe_pids=()

  z.wtproxy._port.keys.from_config config
  for port_key in ${(@)REPLY}; do
    z.wtproxy._port.proxy $port_key || return 1
    local proxy_port=$REPLY
    z.io.null ztcp -l $proxy_port || return 1
    local listener_fd=$REPLY
    listener_keys[$listener_fd]=$port_key
    listener_fds+=($listener_fd)
  done

  trap "z.wtproxy.start._serve.cleanup ${(j: :)listener_fds}; exit 0" INT TERM
  trap "z.wtproxy.start._serve.cleanup ${(j: :)listener_fds}" EXIT

  while true; do
    local -A ready=()
    zselect -A ready $listener_fds || return 1

    for listener_fd in ${(k)ready}; do
      z.wtproxy.start._serve.accept "$listener_fd" "$listener_keys[$listener_fd]" "${(@)listener_fds}"
    done
  done
}
