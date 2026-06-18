source ${z_main}

z.t.describe "z.wtproxy._state.path.has"; {
  z.t.context "pathがstateにある場合"; {
    z.t.it "trueを返す"; {
      z.wtproxy._state.init
      z_wtproxy_state_paths=(/tmp/worktree)

      z.wtproxy._state.path.has /tmp/worktree

      z.t.expect.status.is.true
    }
  }

  z.t.context "pathがstateにない場合"; {
    z.t.it "falseを返す"; {
      z.wtproxy._state.init
      z_wtproxy_state_paths=(/tmp/other)

      z.wtproxy._state.path.has /tmp/worktree

      z.t.expect.status.is.false
    }
  }
}
