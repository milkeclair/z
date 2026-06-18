# accept a client connection and start piping to upstream
#
# $1: listener file descriptor
# $2: target port key
# REPLY: null
# return: null
#
# example:
#  z.wtproxy.start._serve.accept 10 worktree_port_1
z.wtproxy.start._serve.accept() {
  local listener_fd=$1
  local target_key=$2

  z.io.null ztcp -a -t $listener_fd || return
  local client_fd=$REPLY

  z.wtproxy.start._serve.remote.host $client_fd
  local remote_host=$REPLY
  # 0.0.0.0は閉じる(怖いので)
  if ! z.wtproxy.start._serve.host.is.localhost $remote_host; then
    z.io.null ztcp -c $client_fd
    return
  fi

  z.wtproxy._entry.active || { z.io.null ztcp -c $client_fd; return; }
  local -A entry=("${(@)REPLY}")

  z.io.null ztcp $z_wtproxy_host $entry[$target_key]
  local exit_status=$?
  local upstream_fd=$REPLY
  if z.int.is.not.zero $exit_status; then
    z.io.null ztcp -c $client_fd
    return
  fi

  z.wtproxy.start._serve.pipe.pair $client_fd $upstream_fd &
  z_wtproxy_serve_pipe_pids+=($!)
  z.io.null ztcp -c $client_fd
  z.io.null ztcp -c $upstream_fd
}

# clean up proxy listener file descriptors and pid file
#
# $@: listener file descriptors
# REPLY: null
# return: null
#
# example:
#  z.wtproxy.start._serve.cleanup 11 12 13
z.wtproxy.start._serve.cleanup() {
  for pid in $z_wtproxy_serve_pipe_pids; do
    z.io.null kill -TERM "$pid"
  done

  for fd in "$@"; do
    z.io.null ztcp -c $fd
  done

  z.io.null z.wtproxy._config.value pid_file || return
  local pid_file=$REPLY
  z.file.read path=$pid_file
  if z.file.exists $pid_file && z.is.eq "$REPLY" "$$"; then
    rm -f $pid_file
  fi
}
