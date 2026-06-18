source ${z_main}

z.t.describe "z.wtproxy.rm._current"; {
  z.t.context "worktree rootが取得できる場合"; {
    z.t.it "state lock内の削除処理を呼び出す"; {
      z.t.mock name="z.git.wt.current.root" behavior="z.return /tmp/worktree"
      z.t.mock name="z.wtproxy._state.with_lock"

      z.wtproxy.rm._current expected_project=project_feat

      z.t.mock.result name="z.wtproxy._state.with_lock"
      z.t.expect.reply.is.arr z.wtproxy.rm._current.locked /tmp/worktree project_feat
    }
  }
}
