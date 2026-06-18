source ${z_main}

z.t.describe "z.wtproxy.prune._stale"; {
  z.t.context "呼び出した場合"; {
    z.t.it "state lock内のprune処理を呼び出す"; {
      z.t.mock name="z.wtproxy._state.with_lock"

      z.wtproxy.prune._stale

      z.t.mock.result name="z.wtproxy._state.with_lock"
      z.t.expect.reply z.wtproxy.prune._stale.locked
    }
  }
}
