source ${z_main}

z.t.describe "z.mod._store.ensure"; {
  z.t.context "storeが未定義の場合"; {
    z.t.it "storeを初期化する"; {
      unset z_mod_names
      unset z_mod_depends
      unset z_mod_current

      z.mod._store.ensure

      z.var.exists z_mod_names
      z.t.expect.status.is.true skip_unmock=true
      z.var.exists z_mod_depends
      z.t.expect.status.is.true skip_unmock=true
      z.var.exists z_mod_current
      z.t.expect.status.is.true skip_unmock=true
      z.t.expect "$z_mod_current" ""
    }
  }
}
