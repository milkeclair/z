source ${z_main}

z.t.describe "z.wtproxy._entry.current.locked"; {
  z.t.context "activateがtrueの場合"; {
    z.t.it "entryを保存してactive pathを更新する"; {
      z.wtproxy._state.init
      z.t.mock name="z.wtproxy._state.load" behavior="z.wtproxy._state.init"
      z.t.mock name="z.wtproxy._entry.ensure" behavior='
        local -A entry=(path "$1" branch "$2" compose_project_name project_feat)
        z.return.hash entry
      '
      z.t.mock name="z.wtproxy._state.save" behavior="return 0"

      z.wtproxy._entry.current.locked /tmp/worktree feat/example true
      local -A entry=("${(@)REPLY}")

      z.t.expect "$z_wtproxy_state_active_path" /tmp/worktree
      z.t.expect "$entry[path]" /tmp/worktree
    }
  }

  z.t.context "activateがfalseの場合"; {
    z.t.it "active pathを更新しない"; {
      z.wtproxy._state.init
      z.t.mock name="z.wtproxy._state.load" behavior="z.wtproxy._state.init"
      z.t.mock name="z.wtproxy._entry.ensure" behavior='
        local -A entry=(path "$1" branch "$2" compose_project_name project_feat)
        z.return.hash entry
      '
      z.t.mock name="z.wtproxy._state.save" behavior="return 0"

      z.wtproxy._entry.current.locked /tmp/worktree feat/example false

      z.t.expect "$z_wtproxy_state_active_path" ""
    }
  }
}
