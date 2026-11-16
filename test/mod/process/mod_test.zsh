source ${z_main}

z.t.describe "process mod"; {
  z.t.context "main.zshを読み込んだ場合"; {
    z.t.it "modとして登録される"; {
      z.mod.is.registered process

      z.t.expect.status.is.true
    }
  }

  z.t.context "依存関係を解決する場合"; {
    z.t.it "追加のmodに依存せず自身を返す"; {
      z.mod.dependencies.resolve process

      z.t.expect.reply.is.arr process
    }
  }
}
