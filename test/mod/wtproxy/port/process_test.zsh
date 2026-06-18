source ${z_main}

z.t.describe "z.wtproxy._port.allocate"; {
  z.t.context "利用可能なworktree portがある場合"; {
    z.t.it "proxy portと使用済みportを避けて割り当てる"; {
      z.t.mock name="z.wtproxy._port.proxy" behavior="z.return 3000"
      z.t.mock name="z.wtproxy._port.used" behavior="z.return 3001"
      z.t.mock name="z.wtproxy._port.proxies" behavior="z.return 3000"
      z.t.mock name="z.wtproxy._port.is.free" behavior='
        z.is.eq "$1" 3002
      '

      z.wtproxy._port.allocate /tmp/worktree worktree_port_1

      z.t.expect.reply 3002
    }
  }

  z.t.context "利用可能なworktree portがない場合"; {
    z.t.it "falseを返す"; {
      local old_port_range=$z_wtproxy_port_range
      z_wtproxy_port_range=2
      z.t.mock name="z.wtproxy._port.proxy" behavior="z.return 3000"
      z.t.mock name="z.wtproxy._port.used" behavior="z.return"
      z.t.mock name="z.wtproxy._port.proxies" behavior="z.return"
      z.t.mock name="z.wtproxy._port.is.free" behavior="return 1"
      z.t.mock name="z.io.error"

      z.wtproxy._port.allocate /tmp/worktree worktree_port_1
      z.t.expect.status 1 skip_unmock=true
      z_wtproxy_port_range=$old_port_range
      z.t.mock.result name="z.io.error"
      z.t.expect.reply "No available worktree port for worktree_port_1"
    }
  }
}
