source ${z_main}

z.t.describe "z.wtproxy.rm._current.entry"; {
  z.t.context "worktree rootが取得できる場合"; {
    z.t.it "state lock内のentry取得処理を呼び出す"; {
      z.t.mock name="z.git.wt.current.root" behavior="z.return /tmp/worktree"
      z.t.mock name="z.wtproxy._state.with_lock"

      z.wtproxy.rm._current.entry

      z.t.mock.result name="z.wtproxy._state.with_lock"
      z.t.expect.reply.is.arr z.wtproxy.rm._current.entry.locked /tmp/worktree
    }
  }
}

z.t.describe "z.wtproxy.rm._current.locked"; {
  z.t.context "entryが存在する場合"; {
    z.t.it "entryを削除して結果を返す"; {
      local worktree_path=/tmp/worktree
      z.wtproxy._state.init
      z_wtproxy_state_paths=($worktree_path /tmp/other)
      z_wtproxy_state_compose[$worktree_path]=project_feat
      z.t.mock name="z.wtproxy._state.load" behavior="return 0"
      z.t.mock name="z.wtproxy._state.save" behavior="return 0"

      z.wtproxy.rm._current.locked $worktree_path project_feat
      local -A result=("${(@)REPLY}")

      z.t.expect "$result[removed_path]" $worktree_path
      z.t.expect "$result[removed_project]" project_feat
      z.t.expect "$result[entries_count]" 1
    }
  }

  z.t.context "expected projectとstored projectが異なる場合"; {
    z.t.it "falseを返す"; {
      local worktree_path=/tmp/worktree
      z.wtproxy._state.init
      z_wtproxy_state_paths=($worktree_path)
      z_wtproxy_state_compose[$worktree_path]=project_current
      z.t.mock name="z.wtproxy._state.load" behavior="return 0"
      z.t.mock name="z.io.error"

      z.wtproxy.rm._current.locked $worktree_path project_old

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.io.error"
      z.t.expect.reply "entry changed: /tmp/worktree"
    }
  }
}
