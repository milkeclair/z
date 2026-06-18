source ${z_main}

z.t.describe "z.mod.is.registered"; {
  z.t.context "登録済みmodの場合"; {
    z.t.it "trueを返す"; {
      z.mod.reset
      z.mod git

      z.mod.is.registered git

      z.t.expect.status.is.true
    }
  }

  z.t.context "未登録modの場合"; {
    z.t.it "falseを返す"; {
      z.mod.reset

      z.mod.is.registered git

      z.t.expect.status.is.false
    }
  }
}
