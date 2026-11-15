source "$z_main"

z.t.describe "z.update.mod._resolve"; {
  z.t.context "推移的な依存がある場合"; {
    z.t.it "dependencyを先に返す"; {
      local dir=/tmp/z_t/update_resolve/transitive
      z.dir.make path="$dir/mod/app"
      z.dir.make path="$dir/mod/base"
      z.file.write path="$dir/mod/app/mod.zsh" content=$'z.mod app\nz.mod.depends base'
      z.file.write path="$dir/mod/base/mod.zsh" content="z.mod base"
      z.update.mod._resolve source="$dir" app
      z.t.expect.reply.is.arr base app
      z.dir.remove path=/tmp/z_t/update_resolve
    }
  }

  z.t.context "複数modで依存が共通の場合"; {
    z.t.it "一度だけ返す"; {
      local dir=/tmp/z_t/update_resolve/shared
      for mod in one two base; do
        z.dir.make path="$dir/mod/$mod"
        z.file.write path="$dir/mod/$mod/mod.zsh" content="z.mod $mod"
      done
      z.file.write path="$dir/mod/one/mod.zsh" content=$'z.mod one\nz.mod.depends base'
      z.file.write path="$dir/mod/two/mod.zsh" content=$'z.mod two\nz.mod.depends base'
      z.update.mod._resolve source="$dir" one two
      z.t.expect.reply.is.arr base one two
      z.dir.remove path=/tmp/z_t/update_resolve
    }
  }

  z.t.context "mod指定がない場合"; {
    z.t.it "空の結果を返す"; {
      local dir=/tmp/z_t/update_resolve/none
      z.dir.make path="$dir"
      z.update.mod._resolve source="$dir"
      local resolve_status=$?
      local result=$REPLY
      z.t.expect "$resolve_status" 0
      REPLY=$result
      z.t.expect.reply.is.null
      z.dir.remove path=/tmp/z_t/update_resolve
    }
  }

  z.t.context "source引数がない場合"; {
    z.t.it "失敗する"; {
      z.update.mod._resolve app
      local resolve_status=$?
      local result=$REPLY
      z.t.expect "$resolve_status" 1
      REPLY=$result
      z.t.expect.reply.is.null
    }
  }

  z.t.context "指定したmodがない場合"; {
    z.t.it "失敗して結果を残さない"; {
      local dir=/tmp/z_t/update_resolve/missing
      z.dir.make path="$dir"
      z.update.mod._resolve source="$dir" unknown
      local resolve_status=$?
      local result=$REPLY
      z.t.expect "$resolve_status" 1
      REPLY=$result
      z.t.expect.reply.is.null
      z.dir.remove path=/tmp/z_t/update_resolve
    }
  }

  z.t.context "metadataがないmod directoryの場合"; {
    z.t.it "そのmodだけを返す"; {
      local dir=/tmp/z_t/update_resolve/plain
      z.dir.make path="$dir/mod/plain"
      z.update.mod._resolve source="$dir" plain
      z.t.expect.reply plain
      z.dir.remove path=/tmp/z_t/update_resolve
    }
  }

  z.t.context "依存が循環している場合"; {
    z.t.it "失敗して結果を残さない"; {
      local dir=/tmp/z_t/update_resolve/cycle
      z.dir.make path="$dir/mod/one"
      z.dir.make path="$dir/mod/two"
      z.file.write path="$dir/mod/one/mod.zsh" content=$'z.mod one\nz.mod.depends two'
      z.file.write path="$dir/mod/two/mod.zsh" content=$'z.mod two\nz.mod.depends one'
      z.update.mod._resolve source="$dir" one 2>/dev/null
      local resolve_status=$?
      local result=$REPLY
      z.t.expect "$resolve_status" 1
      REPLY=$result
      z.t.expect.reply.is.null
      z.dir.remove path=/tmp/z_t/update_resolve
    }
  }

  z.t.context "登録されたdependencyのdirectoryがない場合"; {
    z.t.it "失敗する"; {
      local dir=/tmp/z_t/update_resolve/missing_directory
      z.dir.make path="$dir/mod/app"
      z.file.write path="$dir/mod/app/mod.zsh" content=$'z.mod app\nz.mod.depends absent\nz.mod absent'
      z.update.mod._resolve source="$dir" app
      local resolve_status=$?
      local result=$REPLY
      z.t.expect "$resolve_status" 1
      REPLY=$result
      z.t.expect.reply.is.null
      z.dir.remove path=/tmp/z_t/update_resolve
    }
  }

  z.t.context "呼び出し前にmodが登録されている場合"; {
    z.t.it "既存の登録内容を変更しない"; {
      local dir=/tmp/z_t/update_resolve/scoped
      z.dir.make path="$dir/mod/next"
      z.file.write path="$dir/mod/next/mod.zsh" content="z.mod next"
      z.mod.reset
      z.mod original
      z.update.mod._resolve source="$dir" next
      local result=$REPLY
      z.mod.is.registered original
      local original_status=$?
      z.mod.is.registered next
      local next_status=$?
      z.t.expect "$result" next
      z.t.expect "$original_status" 0
      z.t.expect "$next_status" 1
      z.t.expect "$z_mod_current" original
      z.dir.remove path=/tmp/z_t/update_resolve
    }
  }

}

