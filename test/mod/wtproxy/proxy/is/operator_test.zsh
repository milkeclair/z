source ${z_main}

z.t.describe "z.wtproxy._proxy.is.running"; {
  z.t.context "pid fileがありpidがwtproxy daemonの場合"; {
    z.t.it "trueを返す"; {
      local pid_file=/tmp/z_t/wtproxy_pid/project.pid
      z.dir.make path=${pid_file:h}
      print -r -- 12345 > $pid_file
      z.t.mock name="z.wtproxy._config.value" behavior="z.return $pid_file"
      z.t.mock name="z.wtproxy._proxy.is.pid" behavior="return 0"

      z.wtproxy._proxy.is.running

      z.t.expect.status.is.true
    }
  }
}

z.t.describe "z.wtproxy._proxy.is.pid"; {
  z.t.context "pidのcommandがwtproxy daemonの場合"; {
    z.t.it "trueを返す"; {
      z.t.mock name="kill" behavior="return 0"
      z.t.mock name="ps" behavior="z.io 'zsh -fc source main.zsh && z.wtproxy.start._serve'"

      z.wtproxy._proxy.is.pid 12345

      z.t.expect.status.is.true
    }
  }

  z.t.context "pidのcommandがwtproxy daemonではない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="kill" behavior="return 0"
      z.t.mock name="ps" behavior="z.io '/usr/bin/zsh -i'"

      z.wtproxy._proxy.is.pid 12345

      z.t.expect.status.is.false
    }
  }
}
