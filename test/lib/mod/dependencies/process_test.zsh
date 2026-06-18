source ${z_main}

z.t.describe "z.mod.dependencies.resolve"; {
  z.t.context "transitive dependencyがある場合"; {
    z.t.it "dependencyを先に並べる"; {
      z.mod.reset
      z.mod git
      z.mod docker; {
        z.mod.depends git
      }
      z.mod wt_proxy; {
        z.mod.depends docker
      }

      z.mod.dependencies.resolve wt_proxy

      z.t.expect.reply.is.arr git docker wt_proxy
    }
  }

  z.t.context "同じdependencyが複数回出る場合"; {
    z.t.it "一度だけ返す"; {
      z.mod.reset
      z.mod git
      z.mod docker; {
        z.mod.depends git
      }
      z.mod wt_proxy; {
        z.mod.depends git docker
      }

      z.mod.dependencies.resolve wt_proxy

      z.t.expect.reply.is.arr git docker wt_proxy
    }
  }
}

z.t.describe "z.mod.dependencies._resolve"; {
  z.t.context "dependencyがある場合"; {
    z.t.it "dependencyを先にresolved namesへ追加する"; {
      z.mod.reset
      z.mod git
      z.mod wt_proxy; {
        z.mod.depends git
      }
      local -a resolved_mod_names=()
      local -A resolving_mod_name_map=()
      local -A resolved_mod_name_map=()

      z.mod.dependencies._resolve wt_proxy

      z.t.expect.status.is.true skip_unmock=true
      z.return ${resolved_mod_names[@]}
      z.t.expect.reply.is.arr git wt_proxy skip_unmock=true
      z.t.expect "$resolved_mod_name_map[git]" true skip_unmock=true
      z.t.expect "$resolved_mod_name_map[wt_proxy]" true
      z.mod.reset
      unset resolved_mod_names resolving_mod_name_map resolved_mod_name_map
    }
  }

  z.t.context "すでにresolvedの場合"; {
    z.t.it "重複してresolved namesへ追加しない"; {
      z.mod.reset
      z.mod git
      local -a resolved_mod_names=(git)
      local -A resolving_mod_name_map=()
      local -A resolved_mod_name_map=(git true)

      z.mod.dependencies._resolve git

      z.t.expect.status.is.true skip_unmock=true
      z.return ${resolved_mod_names[@]}
      z.t.expect.reply.is.arr git
      z.mod.reset
      unset resolved_mod_names resolving_mod_name_map resolved_mod_name_map
    }
  }

  z.t.context "cycleがある場合"; {
    z.t.it "失敗する"; {
      z.mod.reset
      z.t.mock name="z.io.error"
      z.mod git; {
        z.mod.depends wt_proxy
      }
      z.mod wt_proxy; {
        z.mod.depends git
      }
      local -a resolved_mod_names=()
      local -A resolving_mod_name_map=()
      local -A resolved_mod_name_map=()

      z.mod.dependencies._resolve wt_proxy

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.io.error"
      z.t.expect.reply "cyclic mod dependency: wt_proxy"
    }
  }

  z.t.context "未登録modの場合"; {
    z.t.it "失敗する"; {
      z.mod.reset
      z.t.mock name="z.io.error"
      local -a resolved_mod_names=()
      local -A resolving_mod_name_map=()
      local -A resolved_mod_name_map=()

      z.mod.dependencies._resolve unknown

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.io.error"
      z.t.expect.reply "mod is not registered: unknown"
    }
  }
}
