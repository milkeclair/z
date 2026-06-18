source ${z_main}

z.t.describe "z.wtproxy._port.worktree.key"; {
  z.t.context "indexを指定した場合"; {
    z.t.it "worktree port keyを返す"; {
      z.wtproxy._port.worktree.key 2

      z.t.expect.reply "worktree_port_2"
    }
  }
}

z.t.describe "z.wtproxy._port.worktree.index"; {
  z.t.context "worktree port keyを指定した場合"; {
    z.t.it "indexを返す"; {
      z.wtproxy._port.worktree.index worktree_port_12
      local port_index=$REPLY

      z.t.expect.status.is.true
      z.t.expect "$port_index" 12
    }
  }

  z.t.context "worktree port keyではない値を指定した場合"; {
    z.t.it "falseを返してREPLYを空にする"; {
      z.wtproxy._port.worktree.index proxy_port_1

      z.t.expect.status.is.false
      z.t.expect.reply.is.null
    }
  }
}
