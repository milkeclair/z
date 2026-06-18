source ${z_main}

z.t.describe "z.wtproxy._entry.active.locked"; {
  z.t.context "active pathがstateに存在する場合"; {
    z.t.it "active entryを返す"; {
      local worktree_path=/tmp/z_t/wtproxy_active/worktree
      z.dir.make path=$worktree_path
      z.t.mock name="z.wtproxy._state.load" behavior="
        z.wtproxy._state.init
        z_wtproxy_state_active_path=$worktree_path
      "
      z.t.mock name="z.wtproxy._state.path.has" behavior="return 0"
      z.t.mock name="z.wtproxy._state.entry" behavior='
        local -A entry=(path "$1" branch feat/example compose_project_name project_feat)
        z.return.hash entry
      '

      z.wtproxy._entry.active.locked
      local -A entry=("${(@)REPLY}")

      z.t.expect.status.is.true
      z.t.expect "$entry[path]" "$worktree_path"
    }
  }

  z.t.context "active pathが空の場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.wtproxy._state.load" behavior="z.wtproxy._state.init"

      z.wtproxy._entry.active.locked

      z.t.expect.status.is.false
    }
  }
}
