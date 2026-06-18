source ${z_main}

z.t.describe "z.wtproxy.start._daemon"; {
  z.t.context "proxy daemonがすでに起動している場合"; {
    z.t.it "何もしないでtrueを返す"; {
      z.t.mock name="z.wtproxy._proxy.is.running" behavior="return 0"
      z.t.mock name="z.wtproxy._config" behavior="return 1"

      z.wtproxy.start._daemon

      z.t.expect.status.is.true
    }
  }

  z.t.context "configが取得できない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.wtproxy._proxy.is.running" behavior="return 1"
      z.t.mock name="z.wtproxy._config" behavior="return 1"

      z.wtproxy.start._daemon

      z.t.expect.status.is.false
    }
  }

  z.t.context "daemonを開始できる場合"; {
    z.t.it "state dirとlog fileを用意してpid fileを書き込む"; {
      local base_dir=/tmp/z_t/wtproxy_daemon_success
      local fake_bin=$base_dir/bin
      local fake_zsh=$fake_bin/zsh
      local state_dir=$base_dir/state
      local log_file=$base_dir/log/wtproxy.log
      local pid_file=$base_dir/wtproxy.pid
      local -A config=(
        state_dir $state_dir
        log_file $log_file
        pid_file $pid_file
      )
      z.dir.make path=$fake_bin
      z.file.write path=$fake_zsh content=$'#!/bin/sh\nprintf "%s\\n" "$@"\n'
      z.perm path=$fake_zsh mode=700
      z.t.mock name="z.wtproxy._proxy.is.running" behavior="return 1"
      z.t.mock name="z.wtproxy._config" behavior="z.return.hash config"
      z.t.mock name="z.wtproxy._proxy.is.pid" behavior="return 0"

      PATH=$fake_bin:$PATH z.wtproxy.start._daemon

      z.t.expect.status.is.true skip_unmock=true
      z.dir.exists $state_dir
      z.t.expect.status.is.true skip_unmock=true
      z.file.exists $log_file
      z.t.expect.status.is.true skip_unmock=true
      z.file.read path=$log_file
      z.t.expect.reply.includes "z.wtproxy.start._serve" skip_unmock=true
      z.file.read path=$pid_file
      z.t.expect.reply.is.not.null
    }
  }

  z.t.context "起動したprocessがdaemonではない場合"; {
    z.t.it "pid fileを削除してfalseを返す"; {
      local base_dir=/tmp/z_t/wtproxy_daemon_failure
      local fake_bin=$base_dir/bin
      local fake_zsh=$fake_bin/zsh
      local state_dir=$base_dir/state
      local log_file=$base_dir/log/wtproxy.log
      local pid_file=$base_dir/wtproxy.pid
      local -A config=(
        state_dir $state_dir
        log_file $log_file
        pid_file $pid_file
      )
      z.dir.make path=$fake_bin
      z.file.write path=$fake_zsh content=$'#!/bin/sh\nexit 0\n'
      z.perm path=$fake_zsh mode=700
      z.t.mock name="z.wtproxy._proxy.is.running" behavior="return 1"
      z.t.mock name="z.wtproxy._config" behavior="z.return.hash config"
      z.t.mock name="z.wtproxy._proxy.is.pid" behavior="return 1"
      z.t.mock name="kill" behavior="print -r -- \"$*\" >> /tmp/z_t/wtproxy_daemon_failure/kill_calls"
      z.t.mock name="z.io.error" behavior=":"

      PATH=$fake_bin:$PATH z.wtproxy.start._daemon

      z.t.expect.status.is.false skip_unmock=true
      z.file.not.exists $pid_file
      z.t.expect.status.is.true skip_unmock=true
      z.t.mock.result name="kill"
      z.t.expect.reply.includes "-TERM" skip_unmock=true
      z.t.mock.result name="z.io.error"
      z.t.expect.reply "Proxy failed to start. See $log_file"
    }
  }
}

z.t.describe "z.wtproxy.start._serve"; {
  z.t.context "configが取得できない場合"; {
    z.t.it "falseを返す"; {
      disable zmodload 2>/dev/null
      z.t.mock name="zmodload" behavior="return 0"
      z.t.mock name="z.wtproxy._config" behavior="return 1"

      z.wtproxy.start._serve

      z.t.expect.status.is.false
    }
  }

  z.t.context "proxy portが取得できない場合"; {
    z.t.it "listenを開始せずfalseを返す"; {
      local base_dir=/tmp/z_t/wtproxy_serve_proxy_port_failure
      local -A config=(
        state_dir $base_dir/state
        pid_file $base_dir/wtproxy.pid
      )
      disable zmodload 2>/dev/null
      disable ztcp 2>/dev/null
      z.t.mock name="zmodload" behavior="return 0"
      z.t.mock name="ztcp" behavior="return 0"
      z.t.mock name="z.wtproxy._config" behavior="z.return.hash config"
      z.t.mock name="z.wtproxy._port.keys.from_config" behavior="z.return worktree_port_1"
      z.t.mock name="z.wtproxy._port.proxy" behavior="return 1"

      z.wtproxy.start._serve

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="ztcp"
      z.t.expect.reply.is.arr
    }
  }

  z.t.context "proxy portをlistenできない場合"; {
    z.t.it "falseを返す"; {
      local base_dir=/tmp/z_t/wtproxy_serve_listen_failure
      local ztcp_calls=$base_dir/ztcp_calls
      local -A config=(
        state_dir $base_dir/state
        pid_file $base_dir/wtproxy.pid
      )
      z.dir.make path=$base_dir
      z.file.write path=$ztcp_calls content=""
      disable zmodload 2>/dev/null
      disable ztcp 2>/dev/null
      z.t.mock name="zmodload" behavior="return 0"
      z.t.mock name="ztcp" behavior='
        print -r -- "$*" >> /tmp/z_t/wtproxy_serve_listen_failure/ztcp_calls
        return 1
      '
      z.t.mock name="z.wtproxy._config" behavior="z.return.hash config"
      z.t.mock name="z.wtproxy._port.keys.from_config" behavior="z.return worktree_port_1"
      z.t.mock name="z.wtproxy._port.proxy" behavior="z.return 3000"

      z.wtproxy.start._serve

      z.t.expect.status.is.false skip_unmock=true
      z.file.read path=$ztcp_calls
      z.t.expect.reply "-l 3000"
    }
  }


  z.t.context "listenerのselectに失敗した場合"; {
    z.t.it "falseを返してcleanupする"; {
      local base_dir=/tmp/z_t/wtproxy_serve_select_failure
      local cleanup_calls=$base_dir/cleanup_calls
      local -A config=(
        state_dir $base_dir/state
        pid_file $base_dir/wtproxy.pid
      )
      z.dir.make path=$base_dir
      z.file.write path=$cleanup_calls content=""
      disable zmodload 2>/dev/null
      disable zselect 2>/dev/null
      disable ztcp 2>/dev/null
      z.t.mock name="zmodload" behavior="return 0"
      z.t.mock name="ztcp" behavior="REPLY=11"
      z.t.mock name="zselect" behavior="return 1"
      z.t.mock name="z.wtproxy._config" behavior="z.return.hash config"
      z.t.mock name="z.wtproxy._port.keys.from_config" behavior="z.return worktree_port_1"
      z.t.mock name="z.wtproxy._port.proxy" behavior="z.return 3000"
      z.t.mock name="z.wtproxy.start._serve.cleanup" behavior="print -r -- \"\$*\" >> /tmp/z_t/wtproxy_serve_select_failure/cleanup_calls"

      (z.wtproxy.start._serve)

      z.t.expect.status.is.false skip_unmock=true
      z.file.read path=$cleanup_calls
      z.t.expect.reply "11"
    }
  }
  z.t.context "listenerがreadyになった場合"; {
    z.t.it "対応するworktree port keyでacceptを呼び出してcleanupする"; {
      local base_dir=/tmp/z_t/wtproxy_serve_accept
      local accept_calls=$base_dir/accept_calls
      local cleanup_calls=$base_dir/cleanup_calls
      local ztcp_calls=$base_dir/ztcp_calls
      local zmodload_calls=$base_dir/zmodload_calls
      local zselect_calls=$base_dir/zselect_calls
      local -A config=(
        state_dir $base_dir/state
        pid_file $base_dir/wtproxy.pid
      )
      z.dir.make path=$base_dir
      z.file.write path=$accept_calls content=""
      z.file.write path=$cleanup_calls content=""
      z.file.write path=$ztcp_calls content=""
      z.file.write path=$zmodload_calls content=""
      z.file.write path=$zselect_calls content=""
      disable zmodload 2>/dev/null
      disable zselect 2>/dev/null
      disable ztcp 2>/dev/null
      z.t.mock name="zmodload" behavior='
        print -r -- "$*" >> /tmp/z_t/wtproxy_serve_accept/zmodload_calls
      '
      z.t.mock name="zselect" behavior='
        print -r -- "$*" >> /tmp/z_t/wtproxy_serve_accept/zselect_calls
        eval "$2[12]=1"
      '
      z.t.mock name="ztcp" behavior='
        print -r -- "$*" >> /tmp/z_t/wtproxy_serve_accept/ztcp_calls
        if z.is.eq "$1" "-l" && z.is.eq "$2" "3000"; then
          REPLY=11
        elif z.is.eq "$1" "-l" && z.is.eq "$2" "3002"; then
          REPLY=12
        fi
      '
      z.t.mock name="z.wtproxy._config" behavior="z.return.hash config"
      z.t.mock name="z.wtproxy._port.keys.from_config" behavior="z.return worktree_port_1 worktree_port_2"
      z.t.mock name="z.wtproxy._port.proxy" behavior='
        if z.is.eq "$1" "worktree_port_1"; then
          z.return 3000
        elif z.is.eq "$1" "worktree_port_2"; then
          z.return 3002
        else
          return 1
        fi
      '
      z.t.mock name="z.wtproxy.start._serve.accept" behavior='
        print -r -- "$*" >> /tmp/z_t/wtproxy_serve_accept/accept_calls
        exit 0
      '
      z.t.mock name="z.wtproxy.start._serve.cleanup" behavior='
        print -r -- "$*" >> /tmp/z_t/wtproxy_serve_accept/cleanup_calls
      '

      (z.wtproxy.start._serve)
      z.t.expect.status.is.true skip_unmock=true
      z.file.read path=$zmodload_calls
      local zmodload_content=$REPLY
      z.file.read path=$ztcp_calls
      local ztcp_content=$REPLY
      z.file.read path=$zselect_calls
      local zselect_content=$REPLY
      z.file.read path=$accept_calls
      local accept_content=$REPLY
      z.file.read path=$cleanup_calls
      local cleanup_content=$REPLY

      z.t.expect.includes "$zmodload_content" "zsh/net/tcp" skip_unmock=true
      z.t.expect.includes "$zmodload_content" "zsh/zselect" skip_unmock=true
      z.t.expect.includes "$zmodload_content" "zsh/system" skip_unmock=true
      z.t.expect.includes "$ztcp_content" "-l 3000" skip_unmock=true
      z.t.expect.includes "$ztcp_content" "-l 3002" skip_unmock=true
      z.t.expect "$zselect_content" "-A ready 11 12" skip_unmock=true
      z.file.exists $base_dir/wtproxy.pid
      z.t.expect.status.is.true skip_unmock=true
      z.t.expect "$accept_content" "12 worktree_port_2" skip_unmock=true
      z.t.expect "$cleanup_content" "11 12"
    }
  }
}
