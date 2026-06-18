source ${z_main}

z.t.describe "z.mod.dependencies"; {
  z.t.context "dependencyがある場合"; {
    z.t.it "direct dependencyを返す"; {
      z.mod.reset
      z.mod wtproxy; {
        z.mod.depends git
      }

      z.mod.dependencies wtproxy

      z.t.expect.reply.is.arr git
    }
  }
}
