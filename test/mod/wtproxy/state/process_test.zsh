source ${z_main}

z.t.describe "z.wtproxy._state.init"; {
  z.t.context "呼び出した場合"; {
    z.t.it "stateを空に初期化する"; {
      local worktree_path=/tmp/worktree
      z_wtproxy_state_active_path=$worktree_path
      z_wtproxy_state_paths=($worktree_path)
      typeset -gA z_wtproxy_state_branch
      z_wtproxy_state_branch[$worktree_path]=feat/example

      z.wtproxy._state.init

      z.t.expect "$z_wtproxy_state_active_path" ""
      z.t.expect "${#z_wtproxy_state_paths[@]}" 0
      z.t.expect "${#z_wtproxy_state_branch[@]}" 0
      z.t.expect "${#z_wtproxy_state_compose[@]}" 0
      z.t.expect "${#z_wtproxy_state_port[@]}" 0
    }
  }
}

z.t.describe "z.wtproxy._state.load"; {
  z.t.context "state fileが存在する場合"; {
    z.t.it "activeとentryを読み込む"; {
      local state_file=/tmp/z_t/wtproxy_state_load/project.state
      local worktree_path=/tmp/z_t/wtproxy_state_load/worktree
      local branch=feat/example
      local compose=project_name
      z.dir.make path=${state_file:h}
      print -r -- "active ${(qqq)worktree_path}" > $state_file
      print -r -- "entry ${(qqq)worktree_path} ${(qqq)branch} ${(qqq)compose} worktree_port_1=3001" >> $state_file
      z.t.mock name="z.wtproxy._config.value" behavior="z.return $state_file"

      z.wtproxy._state.load

      z.t.expect.status.is.true
      z.t.expect "$z_wtproxy_state_active_path" "$worktree_path"
      z.t.expect "${z_wtproxy_state_branch[$worktree_path]}" feat/example
      z.t.expect "${z_wtproxy_state_compose[$worktree_path]}" project_name
      z.wtproxy._state.port.get "$worktree_path" worktree_port_1
      z.t.expect.reply 3001
    }
  }
}

z.t.describe "z.wtproxy._state.save"; {
  z.t.context "entryがある場合"; {
    z.t.it "state fileに保存する"; {
      local state_dir=/tmp/z_t/wtproxy_state_save
      local state_file=$state_dir/project.state
      local worktree_path=/tmp/worktree
      z.wtproxy._state.init
      z_wtproxy_state_active_path=$worktree_path
      z_wtproxy_state_paths=($worktree_path)
      z_wtproxy_state_branch[$worktree_path]=feat/example
      z_wtproxy_state_compose[$worktree_path]=project_name
      z.wtproxy._state.port.set $worktree_path worktree_port_1 3001
      z.t.mock name="z.wtproxy._config" behavior="
        local -A config=(state_dir $state_dir state_file $state_file)
        z.return.hash config
      "
      z.t.mock name="z.wtproxy._port.keys" behavior="z.return worktree_port_1"

      z.wtproxy._state.save
      local content=$(cat $state_file)

      z.t.expect.includes "$content" 'active "/tmp/worktree"'
      z.t.expect.includes "$content" 'entry "/tmp/worktree" "feat/example" "project_name" worktree_port_1=3001'
    }
  }
}

z.t.describe "z.wtproxy._state.with_lock"; {
  z.t.context "関数を指定した場合"; {
    z.t.it "lock中に関数を実行する"; {
      local state_dir=/tmp/z_t/wtproxy_state_lock
      local lock_file=$state_dir/project.lock
      z.t.mock name="z.wtproxy._config" behavior="
        local -A config=(state_dir $state_dir lock_file $lock_file)
        z.return.hash config
      "
      wtproxy_lock_test_fn() {
        z.return "$1:$2"
      }

      z.wtproxy._state.with_lock wtproxy_lock_test_fn left right

      z.t.expect.reply "left:right"
      z.file.exists $lock_file
      z.t.expect.status.is.true
    }
  }
}
