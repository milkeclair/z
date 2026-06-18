source ${z_main}

z.t.describe "z.wtproxy.stop._daemon"; {
  z.t.context "pid fileがありdaemon pidの場合"; {
    z.t.it "TERMを送る"; {
      local pid_file=/tmp/z_t/wtproxy_stop/project.pid
      z.dir.make path=${pid_file:h}
      print -r -- 12345 > $pid_file
      z.t.mock name="z.wtproxy._config.value" behavior="z.return $pid_file"
      z.t.mock name="z.wtproxy._proxy.is.pid" behavior="return 0"
      z.t.mock name="kill" behavior=":"
      z.t.mock name="sleep" behavior=":"

      z.wtproxy.stop._daemon

      z.t.expect.status.is.true skip_unmock=true
      z.t.mock.result name="kill"
      z.t.expect.reply "-TERM 12345"
    }
  }

  z.t.context "pid fileが存在しない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.wtproxy._config.value" behavior="z.return /tmp/z_t/missing.pid"

      z.wtproxy.stop._daemon

      z.t.expect.status.is.false
    }
  }
}
