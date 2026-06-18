# accept a client connection and start piping to upstream
#
# $1: listener file descriptor
# $2: target port key
# REPLY: null
# return: null
#
# example:
#  z.wt_proxy.start._serve.accept 10 worktree_port_1
z.wt_proxy.start._serve.accept() {
  local listener_fd=$1
  local target_key=$2

  ztcp -a -t $listener_fd >/dev/null 2>&1 || return
  local client_fd=$REPLY

  z.wt_proxy.start._serve.remote.host $client_fd
  local remote_host=$REPLY
  # 0.0.0.0は閉じる(怖いので)
  if ! z.wt_proxy.start._serve.host.is.localhost $remote_host; then
    ztcp -c $client_fd >/dev/null 2>&1
    return
  fi

  z.wt_proxy._entry.active || { ztcp -c $client_fd >/dev/null 2>&1; return; }
  local -A entry=("${(@)REPLY}")

  ztcp $z_wt_proxy_host $entry[$target_key] >/dev/null 2>&1
  local exit_status=$?
  local upstream_fd=$REPLY
  if z.int.is.not.zero $exit_status; then
    ztcp -c $client_fd >/dev/null 2>&1
    return
  fi

  z.wt_proxy.start._serve.pipe.pair $client_fd $upstream_fd &
  ztcp -c $client_fd >/dev/null 2>&1
  ztcp -c $upstream_fd >/dev/null 2>&1
}

# clean up proxy listener file descriptors and pid file
#
# $@: listener file descriptors
# REPLY: null
# return: null
#
# example:
#  z.wt_proxy.start._serve.cleanup 11 12 13
z.wt_proxy.start._serve.cleanup() {
  for fd in "$@"; do
    ztcp -c $fd >/dev/null 2>&1
  done

  z.wt_proxy._config.value pid_file >/dev/null 2>&1 || return
  local pid_file=$REPLY
  if z.file.exists $pid_file && z.is.eq "$(<$pid_file)" "$$"; then
    rm -f $pid_file
  fi
}
