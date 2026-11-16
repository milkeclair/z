# クライアント接続を受け付け、上流との中継を開始する
#
# $1: 待受ファイルディスクリプタ
# $2: 対象のポートキー
# $@?: 中継の子プロセスで閉じる待受ファイルディスクリプタ
# REPLY: null
# return: null
#
# example:
#  # FD10が待受中で、activeのworktree_port_1が3001の場合
#  z.wtproxy.start._serve.accept 10 worktree_port_1
#  # 結果: localhostからの接続が127.0.0.1:3001へ中継される
z.wtproxy.start._serve.accept() {
  local listener_fd=$1
  local target_key=$2
  local listener_fds=("${(@)argv[3,-1]}")

  z.io.null ztcp -a -t $listener_fd || return
  local client_fd=$REPLY

  z.wtproxy.start._serve.remote.host $client_fd
  local remote_host=$REPLY
  # 0.0.0.0は閉じる(怖いので)
  if ! z.wtproxy.start._serve.host.is.localhost $remote_host; then
    z.io.null ztcp -c $client_fd
    return
  fi

  local -A entry=()
  if z.is.null "$z_wtproxy_serve_state_file"; then
    z.wtproxy._entry.active || { z.io.null ztcp -c $client_fd; return; }
    entry=("${(@)REPLY}")
  else
    local active_line=""
    z.file.exists "$z_wtproxy_serve_state_file" && IFS= read -r active_line < $z_wtproxy_serve_state_file

    # active lineが違う、またはキャッシュがなければキャッシュミスとする
    if ! z.is.eq "$active_line" "$z_wtproxy_serve_active_line" || z.int.is.zero ${#z_wtproxy_serve_active_entry[@]}; then
      z.wtproxy._entry.active || { z.io.null ztcp -c $client_fd; return; }
      z_wtproxy_serve_active_line=$active_line
      z_wtproxy_serve_active_entry=("${(@)REPLY}")
    fi
    entry=("${(@)z_wtproxy_serve_active_entry}")
  fi

  z.io.null ztcp $z_wtproxy_host $entry[$target_key]
  local exit_status=$?
  local upstream_fd=$REPLY
  if z.int.is.not.zero $exit_status; then
    z.io.null ztcp -c $client_fd
    return
  fi

  (
    for fd in $listener_fds; do
      z.io.null ztcp -c $fd
    done

    z.wtproxy.start._serve.pipe.pair $client_fd $upstream_fd "$entry[path]"
  ) &
  z_wtproxy_serve_pipe_pids+=($!)
  z.io.null ztcp -c $client_fd
  z.io.null ztcp -c $upstream_fd
}

# プロキシの待受ファイルディスクリプタとPIDファイルを片付ける
#
# $@: 待受ファイルディスクリプタの一覧
# REPLY: null
# return: null
#
# example:
#  # このデーモンがFD11、12、13を待受用に開いている場合
#  z.wtproxy.start._serve.cleanup 11 12 13
#  # 結果: 待受FD11、12、13が閉じられる
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
