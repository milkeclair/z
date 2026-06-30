source ${z_main}

z.t.describe "z.job mod"; {
  z.t.context "mod登録を確認する場合"; {
    z.t.it "modとして登録されている"; {
      z.mod.is.registered job

      z.t.expect.status.is.true
    }
  }
}
