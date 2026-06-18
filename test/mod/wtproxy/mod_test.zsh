source ${z_main}

z.t.describe "wtproxy mod"; {
  z.t.context "依存関係を解決する場合"; {
    z.t.it "gitを先に返す"; {
      z.mod.dependencies.resolve wtproxy

      z.t.expect.reply.is.arr git wtproxy
    }
  }
}
