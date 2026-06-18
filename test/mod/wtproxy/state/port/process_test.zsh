source ${z_main}

z.t.describe "z.wtproxy._state.port.set"; {
  z.t.context "portを指定した場合"; {
    z.t.it "stateにportを保存する"; {
      z.wtproxy._state.init

      z.wtproxy._state.port.set /tmp/worktree worktree_port_1 3001
      z.wtproxy._state.port.get /tmp/worktree worktree_port_1

      z.t.expect.reply 3001
    }
  }
}

z.t.describe "z.wtproxy._state.port.unset_path"; {
  z.t.context "同じworktree pathのportがある場合"; {
    z.t.it "該当pathのportだけを削除する"; {
      z.wtproxy._state.init
      z.wtproxy._state.port.set /tmp/worktree worktree_port_1 3001
      z.wtproxy._state.port.set /tmp/other worktree_port_1 3002

      z.wtproxy._state.port.unset_path /tmp/worktree
      z.wtproxy._state.port.get /tmp/worktree worktree_port_1
      z.t.expect.reply.is.null

      z.wtproxy._state.port.get /tmp/other worktree_port_1
      z.t.expect.reply 3002
    }
  }
}
