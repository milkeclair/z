source ${z_main}

z.t.describe "z.wtproxy._state.entry"; {
  z.t.context "worktree pathを指定した場合"; {
    z.t.it "entry hashを返す"; {
      local worktree_path=/tmp/worktree
      z.wtproxy._state.init
      z_wtproxy_state_branch[$worktree_path]=feat/example
      z_wtproxy_state_compose[$worktree_path]=project_example
      z.wtproxy._state.port.set $worktree_path worktree_port_1 3001
      z.t.mock name="z.wtproxy._port.keys" behavior="z.return worktree_port_1"

      z.wtproxy._state.entry $worktree_path
      local -A entry=("${(@)REPLY}")

      z.t.expect "$entry[path]" $worktree_path
      z.t.expect "$entry[branch]" feat/example
      z.t.expect "$entry[compose_project_name]" project_example
      z.t.expect "$entry[worktree_port_1]" 3001
    }
  }
}
