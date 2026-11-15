source ${z_main}

z.t.describe "pj mod"; {
  z.t.context "main.zshを読み込んだ場合"; {
    z.t.it "modとして登録される"; {
      z.mod.is.registered pj
      z.t.expect.status.is.true
    }
  }
}
