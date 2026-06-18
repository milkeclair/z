source ${z_main}

z.t.describe "z.wtproxy._state.port.state_key"; {
  z.t.context "worktree pathとport keyを指定した場合"; {
    z.t.it "state keyを返す"; {
      z.wtproxy._state.port.state_key /tmp/worktree worktree_port_1

      z.t.expect.reply "/tmp/worktree|worktree_port_1"
    }
  }
}

z.t.describe "z.wtproxy._state.port.get"; {
  z.t.context "保存済みportがある場合"; {
    z.t.it "portを返す"; {
      z.wtproxy._state.init
      z.wtproxy._state.port.set /tmp/worktree worktree_port_1 3001

      z.wtproxy._state.port.get /tmp/worktree worktree_port_1

      z.t.expect.reply 3001
    }
  }
}
