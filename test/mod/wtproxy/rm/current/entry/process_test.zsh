source ${z_main}

z.t.describe "z.wtproxy.rm._current.entry.locked"; {
  z.t.context "current entryが存在する場合"; {
    z.t.it "state entryを返す"; {
      z.t.mock name="z.wtproxy._state.load" behavior="return 0"
      z.t.mock name="z.wtproxy._state.path.has" behavior="return 0"
      z.t.mock name="z.wtproxy._state.entry" behavior='
        local -A entry=(path "$1")
        z.return.hash entry
      '

      z.wtproxy.rm._current.entry.locked /tmp/worktree
      local -A entry=("${(@)REPLY}")

      z.t.expect "$entry[path]" /tmp/worktree
    }
  }

  z.t.context "current entryが存在しない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.wtproxy._state.load" behavior="return 0"
      z.t.mock name="z.wtproxy._state.path.has" behavior="return 1"
      z.t.mock name="z.io.error"

      z.wtproxy.rm._current.entry.locked /tmp/worktree

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.io.error"
      z.t.expect.reply "entry not found: /tmp/worktree"
    }
  }
}
