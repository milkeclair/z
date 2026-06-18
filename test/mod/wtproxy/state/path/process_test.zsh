source ${z_main}

z.t.describe "z.wtproxy._state.path.remove"; {
  z.t.context "pathがstateにある場合"; {
    z.t.it "pathと関連stateを削除する"; {
      local worktree_path=/tmp/worktree
      z.wtproxy._state.init
      z_wtproxy_state_active_path=$worktree_path
      z_wtproxy_state_paths=($worktree_path /tmp/other)
      z_wtproxy_state_branch[$worktree_path]=feat/example
      z_wtproxy_state_compose[$worktree_path]=project_example
      z.wtproxy._state.port.set $worktree_path worktree_port_1 3001

      z.wtproxy._state.path.remove $worktree_path

      z.t.expect "$z_wtproxy_state_active_path" ""
      z.t.expect "${z_wtproxy_state_paths[*]}" "/tmp/other"
      z.t.expect "${z_wtproxy_state_branch[$worktree_path]}" ""
      z.t.expect "${z_wtproxy_state_compose[$worktree_path]}" ""
      z.wtproxy._state.port.get $worktree_path worktree_port_1
      z.t.expect.reply.is.null
    }
  }
}
