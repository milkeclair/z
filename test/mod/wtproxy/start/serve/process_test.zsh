source ${z_main}

z.t.describe "z.wtproxy.start._serve.accept"; {
  z.t.context "clientのacceptに失敗した場合"; {
    z.t.it "falseを返して後続処理を呼ばない"; {
      z.t.mock name="ztcp" behavior='
        if z.is.eq "$1" "-a"; then
          return 1
        fi
      '
      z.t.mock name="z.wtproxy.start._serve.remote.host" behavior="z.return 127.0.0.1"
      z.t.mock name="z.wtproxy._entry.active" behavior="return 0"

      z.wtproxy.start._serve.accept 10 worktree_port_1

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.wtproxy.start._serve.remote.host"
      z.t.expect.reply.is.arr skip_unmock=true
      z.t.mock.result name="z.wtproxy._entry.active"
      z.t.expect.reply.is.arr
    }
  }

  z.t.context "remote hostがlocalhostではない場合"; {
    z.t.it "client fdを閉じる"; {
      z.t.mock name="ztcp" behavior='
        if z.is.eq "$1" "-a"; then
          REPLY=20
        fi
      '
      z.t.mock name="z.wtproxy.start._serve.remote.host" behavior="z.return 192.168.1.1"

      z.wtproxy.start._serve.accept 10 worktree_port_1

      z.t.mock.result name="ztcp"
      z.t.expect.reply.is.arr "-a -t 10" "-c 20"
    }
  }

  z.t.context "upstreamへの接続に失敗した場合"; {
    z.t.it "client fdを閉じてpipeを開始しない"; {
      z.t.mock name="ztcp" behavior='
        if z.is.eq "$1" "-a"; then
          REPLY=20
          return 0
        fi
        if z.is.eq "$1" "-c"; then
          return 0
        fi
        return 1
      '
      z.t.mock name="z.wtproxy.start._serve.remote.host" behavior="z.return 127.0.0.1"
      z.t.mock name="z.wtproxy._entry.active" behavior='
        local -A entry=(path /tmp/worktree worktree_port_1 3001)
        z.return.hash entry
      '
      z.t.mock name="z.wtproxy.start._serve.pipe.pair" behavior="return 0"

      z.wtproxy.start._serve.accept 10 worktree_port_1

      z.t.expect.status.is.true skip_unmock=true
      z.t.mock.result name="z.wtproxy.start._serve.pipe.pair"
      z.t.expect.reply.is.arr
    }
  }

  z.t.context "upstreamへ接続できる場合"; {
    z.t.it "client fdとupstream fdのpipeを開始して親側のfdを閉じる"; {
      local ztcp_calls=/tmp/z_t/wtproxy_accept_success_ztcp_calls
      local pipe_calls=/tmp/z_t/wtproxy_accept_success_pipe_calls
      z.dir.make path=${ztcp_calls:h}
      z.file.write path=$ztcp_calls content=""
      z.file.write path=$pipe_calls content=""
      z.t.mock name="ztcp" behavior='
        print -r -- "$*" >> /tmp/z_t/wtproxy_accept_success_ztcp_calls
        if z.is.eq "$1" "-a"; then
          REPLY=20
          return 0
        fi
        if z.is.eq "$1" "-c"; then
          return 0
        fi
        REPLY=30
      '
      z.t.mock name="z.wtproxy.start._serve.remote.host" behavior="z.return 127.0.0.1"
      z.t.mock name="z.wtproxy._entry.active" behavior='
        local -A entry=(path /tmp/worktree worktree_port_1 3001)
        z.return.hash entry
      '
      z.t.mock name="z.wtproxy.start._serve.pipe.pair" behavior='
        print -r -- "$*" >> /tmp/z_t/wtproxy_accept_success_pipe_calls
      '

      z.wtproxy.start._serve.accept 10 worktree_port_1 10 11 12
      z.t.expect.status.is.true skip_unmock=true
      sleep 0.1
      z.file.read path=$ztcp_calls
      local ztcp_content=$REPLY
      z.file.read path=$pipe_calls
      local pipe_content=$REPLY

      z.t.expect.includes "$ztcp_content" "-a -t 10" skip_unmock=true
      z.t.expect.includes "$ztcp_content" "$z_wtproxy_host 3001" skip_unmock=true
      z.t.expect.includes "$ztcp_content" "-c 10" skip_unmock=true
      z.t.expect.includes "$ztcp_content" "-c 11" skip_unmock=true
      z.t.expect.includes "$ztcp_content" "-c 12" skip_unmock=true
      z.t.expect.includes "$ztcp_content" "-c 20" skip_unmock=true
      z.t.expect.includes "$ztcp_content" "-c 30" skip_unmock=true
      z.t.expect "$pipe_content" "20 30 /tmp/worktree"
    }
  }


  z.t.context "active entry cacheが有効な場合"; {
    z.t.it "activeを読まずにcached entryでpipeを開始する"; {
      local state_file=/tmp/z_t/wtproxy_accept_cached_active/state
      local pipe_calls=/tmp/z_t/wtproxy_accept_cached_active/pipe_calls
      z.dir.make path=${state_file:h}
      z.file.write path=$state_file content="active \"/tmp/worktree\""
      z.file.write path=$pipe_calls content=""
      z_wtproxy_serve_state_file=$state_file
      z_wtproxy_serve_active_line="active \"/tmp/worktree\""
      z_wtproxy_serve_active_entry=(path /tmp/worktree worktree_port_1 3001)
      z.t.mock name="ztcp" behavior="
        if z.is.eq \"\$1\" \"-a\"; then
          REPLY=20
          return 0
        fi
        if z.is.eq \"\$1\" \"-c\"; then
          return 0
        fi
        REPLY=30
      "
      z.t.mock name="z.wtproxy.start._serve.remote.host" behavior="z.return 127.0.0.1"
      z.t.mock name="z.wtproxy._entry.active" behavior="return 1"
      z.t.mock name="z.wtproxy.start._serve.pipe.pair" behavior="
        print -r -- \"\$*\" >> /tmp/z_t/wtproxy_accept_cached_active/pipe_calls
      "

      z.wtproxy.start._serve.accept 10 worktree_port_1 10 11
      z.t.expect.status.is.true skip_unmock=true
      z.t.mock.result name="z.wtproxy._entry.active"
      z.t.expect.reply.is.arr skip_unmock=true
      z.file.read path=$pipe_calls
      z.t.expect.reply "20 30 /tmp/worktree" skip_unmock=true
      z_wtproxy_serve_state_file=""
      z_wtproxy_serve_active_line=""
      z_wtproxy_serve_active_entry=()
    }
  }

  z.t.context "active entryがない場合"; {
    z.t.it "client fdを閉じる"; {
      z.t.mock name="ztcp" behavior='
        if z.is.eq "$1" "-a"; then
          REPLY=20
        fi
      '
      z.t.mock name="z.wtproxy.start._serve.remote.host" behavior="z.return 127.0.0.1"
      z.t.mock name="z.wtproxy._entry.active" behavior="return 1"

      z.wtproxy.start._serve.accept 10 worktree_port_1

      z.t.mock.result name="ztcp"
      z.t.expect.reply.is.arr "-a -t 10" "-c 20"
    }
  }
}

z.t.describe "z.wtproxy.start._serve.cleanup"; {
  z.t.context "pid fileが自分のpidの場合"; {
    z.t.it "listener fdとpid fileを削除する"; {
      local pid_file=/tmp/z_t/wtproxy_cleanup/project.pid
      z.dir.make path=${pid_file:h}
      print -r -- $$ > $pid_file
      typeset -ga z_wtproxy_serve_pipe_pids=(12345 23456)
      z.t.mock name="kill" behavior=":"
      z.t.mock name="ztcp" behavior=":"
      z.t.mock name="z.wtproxy._config.value" behavior="z.return $pid_file"

      z.wtproxy.start._serve.cleanup 11 12

      z.t.mock.result name="kill"
      z.t.expect.reply.is.arr "-TERM 12345" "-TERM 23456" skip_unmock=true
      z.t.mock.result name="ztcp"
      z.t.expect.reply.is.arr "-c 11" "-c 12"
      z.file.not.exists $pid_file
      z.t.expect.status.is.true
      z_wtproxy_serve_pipe_pids=()
    }
  }
}
