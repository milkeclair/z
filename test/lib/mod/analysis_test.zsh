source ${z_main}

z.t.describe "z.mod.dependencies"; {
  z.t.context "dependencyがある場合"; {
    z.t.it "direct dependencyを返す"; {
      z.mod.reset
      z.mod wt_proxy; {
        z.mod.depends git
      }

      z.mod.dependencies wt_proxy

      z.t.expect.reply.is.arr git
    }
  }
}
