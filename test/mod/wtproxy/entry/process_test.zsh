source ${z_main}

z.t.describe "z.wtproxy._entry.current"; {
  z.t.context "current worktreeとbranchが取得できる場合"; {
    z.t.it "state lock内のcurrent処理を呼び出す"; {
      z.t.mock name="z.git.wt.current.root" behavior="z.return /tmp/worktree"
      z.t.mock name="z.git.branch.label.current" behavior="z.return feat/example"
      z.t.mock name="z.wtproxy._state.with_lock"

      z.wtproxy._entry.current activate=true

      z.t.mock.result name="z.wtproxy._state.with_lock"
      z.t.expect.reply.is.arr z.wtproxy._entry.current.locked /tmp/worktree feat/example 0
    }
  }
}

z.t.describe "z.wtproxy._entry.active"; {
  z.t.context "呼び出した場合"; {
    z.t.it "state lock内のactive処理を呼び出す"; {
      z.t.mock name="z.wtproxy._state.with_lock"

      z.wtproxy._entry.active

      z.t.mock.result name="z.wtproxy._state.with_lock"
      z.t.expect.reply z.wtproxy._entry.active.locked
    }
  }
}

z.t.describe "z.wtproxy._entry.ensure"; {
  z.t.context "entryが存在しない場合"; {
    z.t.it "portとcompose project名を割り当てる"; {
      z.wtproxy._state.init
      z.t.mock name="z.wtproxy._port.keys" behavior="z.return worktree_port_1"
      z.t.mock name="z.wtproxy._port.allocate" behavior="z.return 3001"
      z.t.mock name="z.wtproxy._entry.compose.name" behavior="z.return project_feat"

      z.wtproxy._entry.ensure /tmp/worktree feat/example
      local -A entry=("${(@)REPLY}")

      z.t.expect "$entry[path]" /tmp/worktree
      z.t.expect "$entry[branch]" feat/example
      z.t.expect "$entry[compose_project_name]" project_feat
      z.t.expect "$entry[worktree_port_1]" 3001
    }
  }

  z.t.context "portがすでに存在する場合"; {
    z.t.it "portを再割り当てしない"; {
      z.wtproxy._state.init
      z_wtproxy_state_paths=(/tmp/worktree)
      z_wtproxy_state_compose["/tmp/worktree"]=project_feat
      z.wtproxy._state.port.set /tmp/worktree worktree_port_1 3001
      z.t.mock name="z.wtproxy._port.keys" behavior="z.return worktree_port_1"
      z.t.mock name="z.wtproxy._port.allocate" behavior="return 1"

      z.wtproxy._entry.ensure /tmp/worktree feat/example
      local -A entry=("${(@)REPLY}")

      z.t.expect.status.is.true
      z.t.expect "$entry[worktree_port_1]" 3001
    }
  }
}
